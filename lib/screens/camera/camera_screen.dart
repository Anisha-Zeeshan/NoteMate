import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../camera/ocr_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final TextRecognizer _recognizer =
  TextRecognizer(script: TextRecognitionScript.latin);
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Live detection
  String _liveText = '';
  bool _textDetected = false;

  // Zoom
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;

  // Frozen / select mode
  bool _isFrozen = false;
  File? _frozenImageFile;
  RecognizedText? _frozenOCR;
  Size _frozenImageSize = Size.zero;
  List<TextElement> _selectedElements = [];
  Offset? _dragStart;
  Offset? _dragEnd;
  bool _isCapturing = false;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;
      _controller!.startImageStream(_processFrame);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || _isFrozen) return;
    _isProcessing = true;
    try {
      final bytes = BytesBuilder();
      for (final p in image.planes) bytes.add(p.bytes);
      final inputImage = InputImage.fromBytes(
        bytes: bytes.toBytes(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
      final result = await _recognizer.processImage(inputImage);
      if (mounted && !_isFrozen) {
        setState(() {
          _liveText = result.text;
          _textDetected = result.text.trim().isNotEmpty;
        });
      }
    } catch (_) {}
    _isProcessing = false;
  }

  Future<void> _captureAndFreeze() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      await _controller?.stopImageStream();

      final xfile = await _controller!.takePicture();
      final imageFile = File(xfile.path);

      final inputImage = InputImage.fromFilePath(xfile.path);
      final result = await _recognizer.processImage(inputImage);

      final bytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      if (mounted) {
        setState(() {
          _isFrozen = true;
          _frozenImageFile = imageFile;
          _frozenOCR = result;
          _frozenImageSize = Size(
            decodedImage.width.toDouble(),
            decodedImage.height.toDouble(),
          );
          _selectedElements = [];
          _dragStart = null;
          _dragEnd = null;
          _isCapturing = false;
        });
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() => _isCapturing = false);
      _controller?.startImageStream(_processFrame);
    }
  }

  void _unfreeze() {
    _frozenImageFile?.delete().catchError((_) {});
    setState(() {
      _isFrozen = false;
      _frozenImageFile = null;
      _frozenOCR = null;
      _selectedElements = [];
      _dragStart = null;
      _dragEnd = null;
    });
    _controller?.startImageStream(_processFrame);
  }

  void _onScaleStart(ScaleStartDetails d) => _baseZoom = _currentZoom;

  void _onScaleUpdate(ScaleUpdateDetails d) async {
    if (_controller == null || _isFrozen) return;
    final z = (_baseZoom * d.scale).clamp(_minZoom, _maxZoom);
    if (z == _currentZoom) return;
    setState(() => _currentZoom = z);
    await _controller!.setZoomLevel(z);
  }

  List<TextElement> get _sortedSelectedElements {
    final list = [..._selectedElements];
    list.sort((a, b) {
      final aTop = a.boundingBox.top;
      final bTop = b.boundingBox.top;
      final avgHeight =
          (a.boundingBox.height + b.boundingBox.height) / 2;
      final threshold = avgHeight * 0.6;
      if ((aTop - bTop).abs() > threshold) {
        return aTop.compareTo(bTop);
      }
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });
    return list;
  }

  String get _selectedText =>
      _sortedSelectedElements.map((e) => e.text).join(' ');

  // Crop bounding area for Gemini
  Future<File?> _cropSelectedRegion() async {
    if (_selectedElements.isEmpty || _frozenImageFile == null) {
      return null;
    }

    try {
      Rect union = _selectedElements.first.boundingBox;
      for (final e in _selectedElements.skip(1)) {
        union = union.expandToInclude(e.boundingBox);
      }

      const pad = 16.0;
      union = Rect.fromLTRB(
        (union.left - pad).clamp(0, _frozenImageSize.width),
        (union.top - pad).clamp(0, _frozenImageSize.height),
        (union.right + pad).clamp(0, _frozenImageSize.width),
        (union.bottom + pad).clamp(0, _frozenImageSize.height),
      );

      final bytes = await _frozenImageFile!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final cropped = img.copyCrop(
        decoded,
        x: union.left.toInt(),
        y: union.top.toInt(),
        width: union.width.toInt().clamp(1, decoded.width),
        height: union.height.toInt().clamp(1, decoded.height),
      );

      final dir = await getTemporaryDirectory();
      final croppedFile = File(
          '${dir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));
      return croppedFile;
    } catch (e) {
      debugPrint('Crop error: $e');
      return null;
    }
  }

  Future<void> _extractText({required bool useWholeImage}) async {
    if (_frozenImageFile == null) return;

    if (!useWholeImage && _selectedElements.isNotEmpty) {
      setState(() => _isCropping = true);
      final croppedFile = await _cropSelectedRegion();
      setState(() => _isCropping = false);

      if (croppedFile != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OCRResultScreen(imageFile: croppedFile),
          ),
        );
        _frozenImageFile?.delete().catchError((_) {});
        return;
      }
    }

    // Default or "Use All" -> passes image file to Gemini
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OCRResultScreen(imageFile: _frozenImageFile),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFrozen ? _buildFrozenView() : _buildLiveView(),
    );
  }

  Widget _buildLiveView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized && _controller != null)
          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: CameraPreview(_controller!),
          )
        else
          const Center(
              child: CircularProgressIndicator(color: Color(0xFFAD1457))),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _topBtn(Icons.close, () => Navigator.pop(context)),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAD1457),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _textDetected ? '✅ Text detected' : '📋 Point camera at text',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),

        if (_textDetected)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _captureAndFreeze,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.text_fields,
                          color: Color(0xFFAD1457), size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Select Text',
                        style: TextStyle(
                          color: Color(0xFFAD1457),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (_isCapturing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFAD1457)),
                  SizedBox(height: 16),
                  Text(
                    'Freezing frame...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFrozenView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight -
            MediaQuery.of(context).padding.bottom -
            160;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _frozenImageFile != null
                      ? GestureDetector(
                    onPanStart: (d) {
                      setState(() {
                        _dragStart = d.localPosition;
                        _dragEnd = d.localPosition;
                      });
                    },
                    onPanUpdate: (d) {
                      setState(() {
                        _dragEnd = d.localPosition;
                        _updateSelection(screenW, screenH);
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _frozenImageFile!,
                          fit: BoxFit.contain,
                          width: screenW,
                        ),
                        if (_frozenOCR != null)
                          ..._buildWordOverlays(screenW, screenH),
                        if (_dragStart != null && _dragEnd != null)
                          CustomPaint(
                            painter: _SelectionPainter(
                              start: _dragStart!,
                              end: _dragEnd!,
                            ),
                          ),
                      ],
                    ),
                  )
                      : const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFAD1457),
                    ),
                  ),
                ),

                // Bottom bar
                Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedElements.isEmpty
                            ? 'Tap words or drag to select text'
                            : '${_selectedElements.length} word${_selectedElements.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAD1457).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFAD1457),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _selectedText,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_selectedElements.isNotEmpty &&
                                  !_isCropping)
                                  ? () => _extractText(useWholeImage: false)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAD1457),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isCropping
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Use Selected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _extractText(useWholeImage: true),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Use All',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _topBtn(Icons.arrow_back, _unfreeze),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 12),
                          SizedBox(width: 5),
                          Text(
                            'SELECT MODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildWordOverlays(double screenW, double screenH) {
    final widgets = <Widget>[];
    if (_frozenOCR == null || _frozenImageSize == Size.zero) return widgets;

    final imgAspect = _frozenImageSize.width / _frozenImageSize.height;
    final screenAspect = screenW / screenH;

    double renderedW, renderedH, offsetX, offsetY;
    if (imgAspect > screenAspect) {
      renderedW = screenW;
      renderedH = screenW / imgAspect;
      offsetX = 0;
      offsetY = (screenH - renderedH) / 2;
    } else {
      renderedH = screenH;
      renderedW = screenH * imgAspect;
      offsetX = (screenW - renderedW) / 2;
      offsetY = 0;
    }

    final scaleX = renderedW / _frozenImageSize.width;
    final scaleY = renderedH / _frozenImageSize.height;

    for (final block in _frozenOCR!.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final r = element.boundingBox;
          final left = offsetX + r.left * scaleX;
          final top = offsetY + r.top * scaleY;
          final width = r.width * scaleX;
          final height = r.height * scaleY;
          final isSelected = _selectedElements.contains(element);

          widgets.add(
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedElements.remove(element);
                    } else {
                      _selectedElements.add(element);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFAD1457).withOpacity(0.55)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFAD1457)
                          : Colors.white.withOpacity(0.4),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  void _updateSelection(double screenW, double screenH) {
    if (_dragStart == null ||
        _dragEnd == null ||
        _frozenOCR == null ||
        _frozenImageSize == Size.zero) return;

    final selRect = Rect.fromPoints(_dragStart!, _dragEnd!);

    final imgAspect = _frozenImageSize.width / _frozenImageSize.height;
    final screenAspect = screenW / screenH;
    double renderedW, renderedH, offsetX, offsetY;
    if (imgAspect > screenAspect) {
      renderedW = screenW;
      renderedH = screenW / imgAspect;
      offsetX = 0;
      offsetY = (screenH - renderedH) / 2;
    } else {
      renderedH = screenH;
      renderedW = screenH * imgAspect;
      offsetX = (screenW - renderedW) / 2;
      offsetY = 0;
    }

    final scaleX = renderedW / _frozenImageSize.width;
    final scaleY = renderedH / _frozenImageSize.height;

    final selected = <TextElement>[];
    for (final block in _frozenOCR!.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final r = element.boundingBox;
          final left = offsetX + r.left * scaleX;
          final top = offsetY + r.top * scaleY;
          final width = r.width * scaleX;
          final height = r.height * scaleY;
          final elementRect = Rect.fromLTWH(left, top, width, height);
          if (selRect.overlaps(elementRect)) {
            selected.add(element);
          }
        }
      }
    }
    _selectedElements = selected;
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  _SelectionPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFAD1457).withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFAD1457)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SelectionPainter old) =>
      old.start != start || old.end != end;
}
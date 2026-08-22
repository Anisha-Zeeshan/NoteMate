import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  int totalNotes = 0;
  int totalSessions = 0;
  int totalTimeSeconds = 0;

  // ── Real per-day data (last 7 days) ──────────
  List<_DayData> weekDays = [];

  // Tooltip
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();

      // Build last 7 days slots
      final days = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return _DayData(
          date: d,
          label: _dayLabel(d.weekday),
          minutes: 0,
          noteCount: 0,
        );
      });

      // ── Fetch notes created per day ───────────
      final notesSnap = await FirebaseFirestore.instance
          .collection('notes')
          .where('userID', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      totalNotes = notesSnap.docs.length;

      for (final doc in notesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final d = ts.toDate();
        for (final slot in days) {
          if (slot.date.year == d.year &&
              slot.date.month == d.month &&
              slot.date.day == d.day) {
            slot.noteCount++;
            // Estimate 5 min per note created
            slot.minutes += 5;
          }
        }
      }

      // ── Fetch real session times ──────────────
      final sessSnap = await FirebaseFirestore.instance
          .collection('sessions')
          .where('userID', isEqualTo: uid)
          .orderBy('createdAt', descending: false)
          .get();

      totalSessions = sessSnap.docs.length;

      for (final doc in sessSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'] as Timestamp?;
        final secs = (data['timeSpent'] as num?)?.toInt() ?? 0;
        totalTimeSeconds += secs;
        if (ts == null) continue;
        final d = ts.toDate();
        for (final slot in days) {
          if (slot.date.year == d.year &&
              slot.date.month == d.month &&
              slot.date.day == d.day) {
            // Add real session minutes
            slot.minutes += (secs / 60).ceil();
          }
        }
      }

      if (mounted) {
        setState(() {
          weekDays = days;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) {
        final now = DateTime.now();
        weekDays = List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return _DayData(
            date: d,
            label: _dayLabel(d.weekday),
            minutes: 0,
            noteCount: 0,
          );
        });
        setState(() => isLoading = false);
      }
    }
  }

  String _dayLabel(int weekday) {
    const labels = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return labels[weekday];
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }

  int get _avgMinutes {
    final active = weekDays.where((d) => d.minutes > 0).length;
    if (active == 0) return 0;
    return weekDays.fold(0, (s, d) => s + d.minutes) ~/ active;
  }

  int get _maxMinutes => weekDays.isEmpty
      ? 1
      : weekDays
      .map((d) => d.minutes)
      .reduce((a, b) => a > b ? a : b)
      .clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDark;
    final bg = isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC);
    final cardBg = isDark ? const Color(0xFF2D0F1C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFAD1457)),
        )
            : RefreshIndicator(
          onRefresh: () async {
            setState(() => isLoading = true);
            await _loadRealData();
          },
          color: const Color(0xFFAD1457),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'Your study performance',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Stat cards ───────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1, // Fixed height ratio to comfortably fit text
                  children: [
                    _statCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      icon: Icons.note_alt_rounded,
                      color: const Color(0xFFAD1457),
                      title: 'Total Notes',
                      value: '$totalNotes',
                      sub: 'notes created',
                    ),
                    _statCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      icon: Icons.timer_rounded,
                      color: Colors.cyan,
                      title: 'Study Time',
                      value: _formatTime(totalTimeSeconds),
                      sub: 'total tracked',
                    ),
                    _statCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      icon: Icons.event_note_rounded,
                      color: Colors.orange,
                      title: 'Sessions',
                      value: '$totalSessions',
                      sub: 'reading sessions',
                    ),
                    _statCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      icon: Icons.trending_up_rounded,
                      color: Colors.purple,
                      title: 'Avg / Day',
                      value: '${_avgMinutes}m',
                      sub: 'on active days',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── LINE CHART ───────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study Minutes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Last 7 days · tap a point for details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFAD1457).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${weekDays.fold(0, (s, d) => s + d.minutes)}m total',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAD1457),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tooltip card
                      if (_touchedIndex != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAD1457).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFAD1457),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Color(0xFFAD1457),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                weekDays[_touchedIndex!].label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFAD1457),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${weekDays[_touchedIndex!].minutes} min studied',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${weekDays[_touchedIndex!].noteCount} notes',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Real line chart
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: (_maxMinutes * 1.3).toDouble().clamp(5, 99999),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (spots) => spots
                                    .map((s) => LineTooltipItem(
                                  '${s.y.toInt()} min',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ))
                                    .toList(),
                              ),
                              touchCallback: (event, response) {
                                if (event is FlTapUpEvent) {
                                  setState(() {
                                    final idx = response?.lineBarSpots?.first.spotIndex;
                                    _touchedIndex = (idx == _touchedIndex) ? null : idx;
                                  });
                                }
                              },
                              handleBuiltInTouches: true,
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: (_maxMinutes / 4).toDouble().clamp(1, 9999),
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.12),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= weekDays.length) {
                                      return const SizedBox();
                                    }
                                    final isToday = i == weekDays.length - 1;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        isToday ? 'Today' : weekDays[i].label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: _touchedIndex == i
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _touchedIndex == i
                                              ? const Color(0xFFAD1457)
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: (_maxMinutes / 4).toDouble().clamp(1, 9999),
                                  getTitlesWidget: (v, meta) => Text(
                                    '${v.toInt()}m',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: weekDays
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.minutes.toDouble(),
                                ))
                                    .toList(),
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: const Color(0xFFAD1457),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                                    radius: _touchedIndex == i
                                        ? 7
                                        : spot.y > 0
                                        ? 4
                                        : 3,
                                    color: _touchedIndex == i
                                        ? const Color(0xFFAD1457)
                                        : spot.y > 0
                                        ? const Color(0xFFAD1457)
                                        : Colors.grey,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFAD1457).withOpacity(0.3),
                                      const Color(0xFFAD1457).withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Daily breakdown ──────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...weekDays.reversed
                          .map((day) => _dayRow(day, isDark, textColor)),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayRow(_DayData day, bool isDark, Color textColor) {
    final isToday = day.date.year == DateTime.now().year &&
        day.date.month == DateTime.now().month &&
        day.date.day == DateTime.now().day;
    final pct = _maxMinutes == 0
        ? 0.0
        : (day.minutes / _maxMinutes).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              isToday ? 'Today' : day.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFFAD1457) : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFAD1457),
                          Color(0xFFFFC107),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            child: Text(
              day.minutes > 0 ? '${day.minutes}m' : '—',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: day.minutes > 0 ? textColor : Colors.grey[400],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: Text(
              day.noteCount > 0 ? '${day.noteCount} 📝' : '',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED STAT CARD WIDGET
  Widget _statCard({
    required Color cardBg,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final DateTime date;
  final String label;
  int minutes;
  int noteCount;
  _DayData({
    required this.date,
    required this.label,
    required this.minutes,
    required this.noteCount,
  });
}
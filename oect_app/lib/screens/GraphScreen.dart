import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphScreen extends StatefulWidget {
  final Stream<double> dataStream;

  const GraphScreen({super.key, required this.dataStream});

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<List<double>> dataPoints = []; // List to hold [X, Y] pairs
  int sampleCounter = 0;
  double minX = 0;
  double maxX = 1;

  @override
  void initState() {
    super.initState();
    widget.dataStream.listen((data) {
      setState(() {
        // Increment the sample counter (X value)
        sampleCounter++;

        // Add the new sample to the data points as [X, Y]
        dataPoints.add([sampleCounter.toDouble(), data]);

        // Keep only the latest 200 data points
        if (dataPoints.length > 200) {
          dataPoints.removeAt(0); // Remove the oldest data point
        }

        // Update the X-axis range to follow the data points smoothly
        minX = dataPoints.first[0];
        maxX = dataPoints.last[0] + 1;  // Add a small margin to the X-axis end
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen orientation
    var orientation = MediaQuery.of(context).orientation;
    bool isPortrait = orientation == Orientation.portrait;

    // Determine the title font size based on screen orientation
    double titleFontSize = isPortrait
        ? MediaQuery.of(context).size.height * 0.02 // Larger in portrait mode
        : MediaQuery.of(context).size.height * 0.05; // Smaller in landscape mode

    // Determine the graph height based on screen size and orientation
    double graphHeight = isPortrait
        ? MediaQuery.of(context).size.height / 2.3
        : MediaQuery.of(context).size.height * 0.6;

    return Scaffold(
      backgroundColor: Color.fromRGBO(0, 51, 102, 1), // Dark blue background
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable automatic leading icon
        title: Center( // Center the title
          child: Text(
            'OECT Device Voltage Output',
            style: TextStyle(
              color: Colors.white, // White text
              fontSize: titleFontSize, // Dynamically adjusted font size
              overflow: TextOverflow.ellipsis, // Handle overflow
            ),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: Color.fromRGBO(0, 51, 102, 1), // Dark blue AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Custom border painter to draw borders
            CustomPaint(
              size: Size(double.infinity, graphHeight),
              painter: BorderPainter(),
            ),
            // The LineChart displaying the real-time data
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: graphHeight, // Dynamically adjust height
                child: LineChart(
                  LineChartData(
                    backgroundColor: Color.fromRGBO(0, 51, 102, 1), // Match graph background
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int xValue = value.toInt();
                            return Text(
                              xValue.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            double step = 0.2;
                            if (value >= 0 && value <= 3.3 && (value * 10).toInt() % (step * 10).toInt() == 0) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: minX - 1,  // Dynamically use the first X value with margin
                    maxX: maxX,  // Dynamically use the last X value with margin
                    minY: 0,
                    maxY: 3.3,
                    lineBarsData: [
                      LineChartBarData(
                        spots: dataPoints
                            .map((point) => FlSpot(point[0], point[1]))
                            .toList(),
                        isCurved: true,
                        color: Colors.white, // Use white for the graph line
                        dotData: FlDotData(show: false),
                        barWidth: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter to add borders
class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white // Border color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw borders around the graph
    canvas.drawLine(Offset(20, 0), Offset(20, size.height - 20), paint);
    canvas.drawLine(Offset(20, size.height - 20), Offset(size.width, size.height - 20), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

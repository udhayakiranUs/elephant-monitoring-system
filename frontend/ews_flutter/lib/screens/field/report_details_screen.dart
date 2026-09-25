import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../models/report_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  final ReportModel report;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  ReportModel get report => widget.report;

  bool _generatingPdf = false;

  Future<List<pw.MemoryImage>> _fetchPdfPhotos() async {
    final urls = [
      ...report.elephantPhotoPaths,
      ...report.damagePhotoPaths,
    ].map(Helpers.resolvePhotoUrl).whereType<String>().toList();

    final images = <pw.MemoryImage>[];

    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          images.add(pw.MemoryImage(response.bodyBytes));
        }
      } catch (e) {
        debugPrint('PDF photo fetch failed for $url: $e');
      }
    }

    return images;
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _generatingPdf = true;
    });

    try {
      final pdf = pw.Document();

      final counts = report.counts.toJson();
      final pdfPhotos = await _fetchPdfPhotos();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ELEPHANT WARNING SYSTEM',
                  style: const pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Coimbatore Forest Division',
                  style: const pw.TextStyle(
                    fontSize: 11,
                  ),
                ),
                pw.Divider(),
              ],
            );
          },
          footer: (context) {
            return pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 9,
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.Text(
                'FIELD INCIDENT REPORT',
                style: const pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 18),

              // INCIDENT DETAILS
              _pdfSection(
                'Incident Details',
                [
                  _pdfRow(
                    'Range',
                    report.range,
                  ),
                  _pdfRow(
                    'Beat / Section',
                    report.beat,
                  ),
                  _pdfRow(
                    'Date & Time',
                    _formatDateTime(report.dateTime),
                  ),
                  _pdfRow(
                    'Latitude',
                    report.lat.toStringAsFixed(4),
                  ),
                  _pdfRow(
                    'Longitude',
                    report.lon.toStringAsFixed(4),
                  ),
                  _pdfRow(
                    'Location',
                    report.locationDescription.isEmpty
                        ? 'Not provided'
                        : report.locationDescription,
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // REPORTING OFFICER
              _pdfSection(
                'Reporting Officer',
                [
                  _pdfRow(
                    'Officer',
                    report.officer,
                  ),
                  _pdfRow(
                    'Designation',
                    report.designation,
                  ),
                  _pdfRow(
                    'Team Members',
                    report.team.isEmpty ? 'Not provided' : report.team,
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // ELEPHANT COUNT
              _pdfSection(
                'Elephant Count',
                [
                  _pdfRow(
                    'Lone Male',
                    '${counts['lm'] ?? 0}',
                  ),
                  _pdfRow(
                    'Male Group',
                    '${counts['mg'] ?? 0}',
                  ),
                  _pdfRow(
                    'Female Group',
                    '${counts['fg'] ?? 0}',
                  ),
                  _pdfRow(
                    'Female + Calf',
                    '${counts['fc'] ?? 0}',
                  ),
                  _pdfRow(
                    'Single Female',
                    '${counts['sf'] ?? 0}',
                  ),
                  _pdfRow(
                    'Makhna',
                    '${counts['mk'] ?? 0}',
                  ),
                  _pdfRow(
                    'TOTAL',
                    '${report.total}',
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // DAMAGE ASSESSMENT
              _pdfSection(
                'Damage Assessment',
                [
                  _pdfRow(
                    'Damage Caused',
                    report.damage ? 'YES' : 'NO',
                  ),
                  if (report.damage)
                    _pdfRow(
                      'Damage Type',
                      report.damageType.isEmpty
                          ? 'Not provided'
                          : report.damageType,
                    ),
                  if (report.damage)
                    _pdfRow(
                      'Description',
                      report.damageDescription.isEmpty
                          ? 'Not provided'
                          : report.damageDescription,
                    ),
                ],
              ),

              pw.SizedBox(height: 14),

              // CHASE BACK
              _pdfSection(
                'Chase-Back Operation',
                [
                  _pdfRow(
                    'Chase Started',
                    report.chaseStart.isEmpty
                        ? 'Not recorded'
                        : report.chaseStart,
                  ),
                  _pdfRow(
                    'Result',
                    report.chaseResult.isEmpty
                        ? 'Not recorded'
                        : report.chaseResult,
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // REMARKS
              _pdfSection(
                'Remarks / Observations',
                [
                  pw.Text(
                    report.remarks.isEmpty
                        ? 'No remarks provided.'
                        : report.remarks,
                    style: const pw.TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // PHOTOGRAPHS
              _pdfSection(
                'Photographs',
                [
                  if (pdfPhotos.isEmpty)
                    _pdfRow(
                      'Photographs',
                      _photoCountText(),
                    )
                  else ...[
                    pw.Text(
                      _photoCountText(),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final img in pdfPhotos)
                          pw.Container(
                            width: 140,
                            height: 100,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.grey400,
                              ),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 4,
                              verticalRadius: 4,
                              child: pw.Image(
                                img,
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                'Generated by Elephant Warning System',
                style: const pw.TextStyle(
                  fontSize: 9,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return pdf.save();
        },
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report generated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not generate PDF: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _photoCountText() {
    final elephantPhotos = report.elephantPhotoPaths.length;
    final damagePhotos = report.damagePhotoPaths.length;
    final totalPhotos = elephantPhotos + damagePhotos;

    if (totalPhotos == 0) {
      return 'No photographs attached';
    }

    return '$totalPhotos photograph(s) attached';
  }

  pw.Widget _pdfSection(
    String title,
    List<pw.Widget> children,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _pdfRow(
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 5,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: AppText.heading(
          size: 16,
          weight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppText.body(
                size: 12,
                color: AppColors.text3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: AppText.body(
                size: 12,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _countRow(
    String label,
    int value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body(
                size: 12,
                color: AppColors.text2,
              ),
            ),
          ),
          Text(
            '$value',
            style: AppText.heading(
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ELEPHANT PHOTOS: ${report.elephantPhotoPaths}');
    debugPrint('DAMAGE PHOTOS: ${report.damagePhotoPaths}');

    final counts = report.counts.toJson();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'REPORT DETAILS',
          style: AppText.heading(
            size: 17,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // REPORT ID
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(
                    alpha: .08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.green.withValues(
                      alpha: .2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report ID',
                            style: AppText.body(
                              size: 10,
                              color: AppColors.text3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report.id,
                            style: AppText.heading(
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // INCIDENT DETAILS
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Incident Details',
                    ),
                    _infoRow(
                      'Range',
                      report.range,
                    ),
                    _infoRow(
                      'Beat / Section',
                      report.beat,
                    ),
                    _infoRow(
                      'Date & Time',
                      _formatDateTime(
                        report.dateTime,
                      ),
                    ),
                    _infoRow(
                      'Latitude',
                      report.lat.toStringAsFixed(6),
                    ),
                    _infoRow(
                      'Longitude',
                      report.lon.toStringAsFixed(6),
                    ),
                    _infoRow(
                      'Location',
                      report.locationDescription,
                    ),
                  ],
                ),
              ),

              // REPORTING OFFICER
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Reporting Officer',
                    ),
                    _infoRow(
                      'Officer',
                      report.officer,
                    ),
                    _infoRow(
                      'Designation',
                      report.designation,
                    ),
                    _infoRow(
                      'Team',
                      report.team,
                    ),
                  ],
                ),
              ),

              // ELEPHANT COUNT
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Elephant Count',
                    ),
                    _countRow(
                      'Lone Male',
                      (counts['lm'] as num?)?.toInt() ?? 0,
                    ),
                    _countRow(
                      'Male Group',
                      (counts['mg'] as num?)?.toInt() ?? 0,
                    ),
                    _countRow(
                      'Female Group',
                      (counts['fg'] as num?)?.toInt() ?? 0,
                    ),
                    _countRow(
                      'Female + Calf',
                      (counts['fc'] as num?)?.toInt() ?? 0,
                    ),
                    _countRow(
                      'Single Female',
                      (counts['sf'] as num?)?.toInt() ?? 0,
                    ),
                    _countRow(
                      'Makhna',
                      (counts['mk'] as num?)?.toInt() ?? 0,
                    ),
                    const Divider(
                      height: 18,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TOTAL',
                            style: AppText.heading(
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${report.total}',
                          style: AppText.heading(
                            size: 20,
                            weight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // DAMAGE ASSESSMENT
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Damage Assessment',
                    ),
                    Row(
                      children: [
                        Icon(
                          report.damage
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color:
                              report.damage ? AppColors.red : AppColors.green,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          report.damage ? 'YES' : 'NO',
                          style: AppText.heading(
                            size: 14,
                            weight: FontWeight.w700,
                            color:
                                report.damage ? AppColors.red : AppColors.green,
                          ),
                        ),
                      ],
                    ),
                    if (report.damage) ...[
                      const SizedBox(height: 14),
                      _infoRow(
                        'Damage Type',
                        report.damageType,
                      ),
                      _infoRow(
                        'Description',
                        report.damageDescription,
                      ),
                    ],
                  ],
                ),
              ),

              // CHASE BACK
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Chase-Back Operation',
                    ),
                    _infoRow(
                      'Chase Started',
                      report.chaseStart,
                    ),
                    _infoRow(
                      'Result',
                      report.chaseResult,
                    ),
                  ],
                ),
              ),

              // REMARKS
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Remarks / Observations',
                    ),
                    Text(
                      report.remarks.isEmpty
                          ? 'No remarks provided.'
                          : report.remarks,
                      style: AppText.body(
                        size: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),

              // PHOTOGRAPHS
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Photographs',
                    ),

                    const SizedBox(height: 8),

                    if (report.elephantPhotoPaths.isEmpty &&
                        report.damagePhotoPaths.isEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: AppColors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No photographs attached',
                              style: AppText.body(
                                size: 12,
                                color: AppColors.text2,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.photo_library_outlined,
                                color: AppColors.green,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _photoCountText(),
                                style: AppText.body(
                                  size: 12,
                                  color: AppColors.text2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final raw in [
                                ...report.elephantPhotoPaths,
                                ...report.damagePhotoPaths,
                              ])
                                if (Helpers.resolvePhotoUrl(raw)
                                    case final url?)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      width: 140,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, progress) {
                                        if (progress == null) return child;
                                        return SizedBox(
                                          width: 140,
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: progress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? progress
                                                          .cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 140,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.green,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.green,
                                            size: 32,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 6),

                    // PDF BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _generatingPdf ? null : _downloadPdf,
                        icon: _generatingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.picture_as_pdf,
                              ),
                        label: Text(
                          _generatingPdf
                              ? 'GENERATING PDF...'
                              : 'DOWNLOAD REPORT AS PDF',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.green.withValues(
                            alpha: .5,
                          ),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

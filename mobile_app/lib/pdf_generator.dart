

// import 'dart:typed_data';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// class PdfGenerator {
//   static Future<Uint8List> generateInvoice({
//     required String invoiceNo,
//     required String shopName,
//     required String customerName,
//     required String customerMobile,
//     required List<Map<String, dynamic>> cartItems,
//     required double totalAmount,
//   }) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header
//               pw.Center(
//                 child: pw.Text(
//                   shopName.toUpperCase(),
//                   style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
//                 ),
//               ),
//               pw.Center(
//                 child: pw.Text('Tax Invoice', style: const pw.TextStyle(fontSize: 14)),
//               ),
//               pw.SizedBox(height: 10),
//               pw.Divider(thickness: 2),
//               pw.SizedBox(height: 10),
              
//               // Invoice Info
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text('Invoice No: $invoiceNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                   pw.Text('Date: ${DateTime.now().toString().substring(0, 10)}'),
//                 ],
//               ),
//               pw.SizedBox(height: 15),
              
//               // Customer Details
//               pw.Container(
//                 padding: const pw.EdgeInsets.all(8),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: PdfColors.black),
//                   borderRadius: pw.BorderRadius.circular(4),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text('Customer Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                     pw.SizedBox(height: 4),
//                     pw.Text('Name: ${customerName.isEmpty ? 'Walk-in Customer' : customerName}'),
//                     if (customerMobile.isNotEmpty) pw.Text('Mobile: $customerMobile'),
//                   ],
//                 ),
//               ),
//               pw.SizedBox(height: 20),
              
//               pw.Table.fromTextArray(
//                 headers: ['S.No', 'Medicine Name', 'Packs', 'Tabs', 'MRP (Rs)', 'Total (Rs)'],
//                 headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
//                 headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
//                 cellAlignment: pw.Alignment.center,
//                 cellAlignments: {
//                   0: pw.Alignment.centerLeft,
//                   1: pw.Alignment.centerLeft,
//                 },
//                 data: List<List<dynamic>>.generate(cartItems.length, (index) {
//                   final item = cartItems[index];
                  
                  
//                   int packs = item['packs'] ?? 0;
//                   int tabs = item['tabs'] ?? 0;
//                   double mrp = item['mrp'] ?? 0.0;
//                   double qty = item['sell_quantity'] ?? 0.0;
//                   double itemTotal = qty * mrp;

//                   return [
//                     (index + 1).toString(),
//                     item['medicine_name'] ?? 'Unknown',
//                     packs.toString(), 
//                     tabs.toString(),  
//                     mrp.toStringAsFixed(2),
//                     itemTotal.toStringAsFixed(2),
//                   ];
//                 }),
//               ),
//               pw.SizedBox(height: 20),
              
//               // Grand Total
//               pw.Align(
//                 alignment: pw.Alignment.centerRight,
//                 child: pw.Text(
//                   'Grand Total: Rs. ${totalAmount.toStringAsFixed(2)}',
//                   style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
//                 ),
//               ),
              
//               pw.SizedBox(height: 40),
              
//               // Footer Message
//               pw.Center(
//                 child: pw.Text(
//                   'Thank you for your visit!\nGet well soon.',
//                   textAlign: pw.TextAlign.center,
//                   style: pw.TextStyle(color: PdfColors.grey700),
//                 ),
//               )
//             ],
//           );
//         },
//       ),
//     );

//     return pdf.save();
//   }
// }


import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  static Future<Uint8List> generateInvoice({
    required String invoiceNo,
    required String shopName,
    required String customerName,
    required String customerMobile,
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount, // Ye ab Subtotal ban jayega
    required double discountAmount, // 🔥 Naya parameter: Discount ke liye
  }) async {
    final pdf = pw.Document();

    // 🔥 Final amount calculation
    final double grandTotal = totalAmount - discountAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text('Tax Invoice', style: const pw.TextStyle(fontSize: 14)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              
              // Invoice Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice No: $invoiceNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateTime.now().toString().substring(0, 10)}'),
                ],
              ),
              pw.SizedBox(height: 15),
              
              // Customer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Name: ${customerName.isEmpty ? 'Walk-in Customer' : customerName}'),
                    if (customerMobile.isNotEmpty) pw.Text('Mobile: $customerMobile'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // 🔥 Table me Expiry ka column add kiya gaya hai
              pw.Table.fromTextArray(
                headers: ['S.No', 'Medicine Name', 'Expiry', 'Packs', 'Tabs', 'MRP (Rs)', 'Total (Rs)'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                },
                data: List<List<dynamic>>.generate(cartItems.length, (index) {
                  final item = cartItems[index];
                  
                  int packs = item['packs'] ?? 0;
                  int tabs = item['tabs'] ?? 0;
                  double mrp = item['mrp'] ?? 0.0;
                  double qty = item['sell_quantity'] ?? 0.0;
                  double itemTotal = qty * mrp;
                  String expDate = item['expiry_date'] ?? '-'; // Expiry date fetch

                  return [
                    (index + 1).toString(),
                    item['medicine_name'] ?? 'Unknown',
                    expDate, 
                    packs.toString(), 
                    tabs.toString(),  
                    mrp.toStringAsFixed(2),
                    itemTotal.toStringAsFixed(2),
                  ];
                }),
              ),
              pw.SizedBox(height: 20),
              
              // 🔥 Grand Total aur Discount ka hisaab
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Subtotal: Rs. ${totalAmount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    if (discountAmount > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Discount: - Rs. ${discountAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                      ),
                    ],
                    pw.SizedBox(height: 5),
                    pw.Container(width: 250, child: pw.Divider(thickness: 1)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Grand Total: Rs. ${grandTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ]
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // Footer Message
              pw.Center(
                child: pw.Text(
                  'Thank you for your visit!\nGet well soon.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(color: PdfColors.grey700),
                ),
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
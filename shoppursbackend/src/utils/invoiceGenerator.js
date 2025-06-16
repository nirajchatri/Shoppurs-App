const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');
const { pool: db } = require('../config/database');

async function generateInvoicePDF({ order, orderItems, invoiceNumber }) {
  try {
    // Fetch app settings from database
    const [appSettings] = await db.promise().query(`
      SELECT 
        company_name, company_address, support_number, support_email, gstin,
        company_logo_url, invoice_note, invoice_footer_text, invoice_prefix,
        default_currency, tax_label_cgst, tax_label_sgst, payment_terms_text
      FROM app_settings 
      LIMIT 1
    `);

    // Use default values if no settings found
    const settings = appSettings[0] || {
      company_name: 'Areeva Products & Services Pvt. Ltd.',
      company_address: 'Hari Nagar, New Delhi, Delhi 110058, India',
      support_number: '9810162596',
      support_email: 'shop.westdelhi@shoppurs.in',
      gstin: '07AAPCA4055P1Z3',
      company_logo_url: null,
      invoice_note: null,
      invoice_footer_text: 'Thank you for shopping at Shoppurs.\nIn case you would like to Exchange any of the products purchased, we request you to carry your bill along.',
      invoice_prefix: 'INV',
      default_currency: '₹',
      tax_label_cgst: 'CGST',
      tax_label_sgst: 'SGST',
      payment_terms_text: 'Payment Method: Cash'
    };

    // Save invoices in uploads/invoice at the project root
    const uploadsDir = path.resolve(__dirname, '../../uploads/invoice');
    if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
    const filePath = path.join(uploadsDir, `${invoiceNumber}.pdf`);
    const doc = new PDFDocument({ margin: 40 }); // Increased margin slightly for better spacing
    const stream = doc.pipe(fs.createWriteStream(filePath));

    // Page dimensions
    const pageWidth = doc.page.width;
    const leftMargin = 40;
    const rightMargin = 40;
    const contentWidth = pageWidth - leftMargin - rightMargin;

    // Header
    doc.fontSize(18).fillColor('#1565c0').text(settings.company_name, { align: 'center' });
    doc.moveDown(0.2);
    doc.fontSize(10).fillColor('black').text(settings.company_address, { align: 'center' });
    doc.text(`Ph: ${settings.support_number}`, { align: 'center' });
    doc.text(`Email: ${settings.support_email}`, { align: 'center' });
    doc.text(`GSTIN: ${settings.gstin}`, { align: 'center' });
    doc.moveDown(1);

    // --- Purchase Details ---
    let y = doc.y;
    doc.fontSize(12).fillColor('#1565c0').text('Purchase Details', leftMargin, y);
    y += 18;
    doc.fontSize(9).fillColor('black').text(`Transaction id: ${order.ORDER_NUMBER || ''}`, leftMargin, y);
    y += 13;
    doc.text(`Date: ${(order.CREATED_DATE || '').toISOString ? order.CREATED_DATE.toISOString().slice(0, 19).replace('T', ' ') : order.CREATED_DATE}`, leftMargin, y);
    y += 18;

    // --- Summary and Payment Details ---
    // Calculate box widths to use full width
    const summaryBoxWidth = contentWidth * 0.48; // 48% of content width
    const paymentBoxWidth = contentWidth * 0.48; // 48% of content width
    const boxGap = contentWidth * 0.04; // 4% gap between boxes
    
    // Draw rectangles
    doc.rect(leftMargin, y, summaryBoxWidth, 80).fill('#e3f2fd').stroke();
    doc.rect(leftMargin + summaryBoxWidth + boxGap, y, paymentBoxWidth, 80).fill('#f5f5f5').stroke();
    
    // Purchase Summary
    doc.fillColor('#1565c0').fontSize(11).text('Purchase Summary', leftMargin + 5, y + 8);
    doc.fillColor('black').fontSize(9).text(`Total Amount: ${settings.default_currency}${order.ORDER_TOTAL || ''}`, leftMargin + 5, y + 25);
    doc.text(`Items: ${orderItems.length}`, leftMargin + 5, y + 40);
    doc.text(`Discounted Items: 0`, leftMargin + 5, y + 55);
    
    // Payment Details
    doc.fillColor('#1565c0').fontSize(11).text('Payment Details', leftMargin + summaryBoxWidth + boxGap + 5, y + 8);
    
    // Handle payment terms text - truncate if too long
    let paymentText = settings.payment_terms_text || 'Payment Method: Cash';
    if (paymentText.length > 25) {
      paymentText = paymentText.substring(0, 22) + '...';
    }
    
    doc.fillColor('black').fontSize(9).text(paymentText, leftMargin + summaryBoxWidth + boxGap + 5, y + 25, {
      width: paymentBoxWidth - 10,
      lineGap: 2
    });
    doc.text(`Amount: ${settings.default_currency}${order.ORDER_TOTAL || ''}`, leftMargin + summaryBoxWidth + boxGap + 5, y + 45);
    y += 90;

    // --- Item Table Header ---
    doc.moveTo(leftMargin, y).lineTo(pageWidth - rightMargin, y).stroke();
    y += 5;
    
    // Calculate column positions for full width usage
    const col1 = leftMargin; // Item Name
    const col2 = leftMargin + contentWidth * 0.45; // Qty
    const col3 = leftMargin + contentWidth * 0.55; // Net Amt
    const col4 = leftMargin + contentWidth * 0.65; // HSN
    const col5 = leftMargin + contentWidth * 0.75; // MRP
    const col6 = leftMargin + contentWidth * 0.85; // CGST%
    const col7 = leftMargin + contentWidth * 0.93; // SGST%
    
    doc.fontSize(10).fillColor('black');
    doc.text('Item Name', col1, y);
    doc.text('Qty', col2, y);
    doc.text('Net Amt', col3, y);
    doc.text('HSN', col4, y);
    doc.text('MRP', col5, y);
    doc.text(settings.tax_label_cgst + '%', col6, y);
    doc.text(settings.tax_label_sgst + '%', col7, y);
    y += 15;
    doc.moveTo(leftMargin, y).lineTo(pageWidth - rightMargin, y).stroke();
    y += 5;

    // --- Item Table Rows ---
    orderItems.forEach(item => {
      doc.fontSize(9).text(item.PROD_NAME, col1, y, { width: contentWidth * 0.4 });
      doc.text(item.QUANTITY, col2, y);
      doc.text(`${settings.default_currency}${item.TOTAL_PRICE}`, col3, y);
      doc.text(item.PROD_HSN_CODE || '', col4, y);
      doc.text(`${settings.default_currency}${item.PROD_MRP || ''}`, col5, y);
      doc.text('6', col6, y);
      doc.text('6', col7, y);
      y += 15;
    });
    y += 5;
    doc.fontSize(9).text('Total Amount', col2, y);
    doc.text(`${settings.default_currency}${order.ORDER_TOTAL || ''}`, col3, y);
    y += 13;
    doc.text('Gross Total', col2, y);
    doc.text(`${settings.default_currency}${order.ORDER_TOTAL || ''}`, col3, y);
    y += 20;

    // --- GST Summary ---
    const gstCol1 = leftMargin;
    const gstCol2 = leftMargin + contentWidth * 0.25;
    const gstCol3 = leftMargin + contentWidth * 0.45;
    const gstCol4 = leftMargin + contentWidth * 0.65;
    
    doc.fontSize(10).text('GST', gstCol1, y);
    doc.text('Taxable Value', gstCol2, y);
    doc.text('Tax(%)', gstCol3, y);
    doc.text('Tax Amt', gstCol4, y);
    y += 13;
    doc.fontSize(9).text(settings.tax_label_cgst, gstCol1, y);
    doc.text('1,321.39', gstCol2, y);
    doc.text('6', gstCol3, y);
    doc.text('79.28', gstCol4, y);
    y += 13;
    doc.text(settings.tax_label_sgst, gstCol1, y);
    doc.text('1,321.39', gstCol2, y);
    doc.text('6', gstCol3, y);
    doc.text('79.28', gstCol4, y);
    y += 13;
    doc.text('Total Tax', gstCol3, y);
    doc.text('243.37', gstCol4, y);
    y += 20;

    // --- Customer and Store Details ---
    doc.fontSize(11).fillColor('#1565c0').text('CUSTOMER DETAILS', leftMargin, y);
    y += 15;
    doc.fontSize(9).fillColor('black').text(`${order.USERNAME}\n${order.MOBILE}`, leftMargin, y);
    y += 25;
    doc.fontSize(11).fillColor('#1565c0').text('STORE DETAILS', leftMargin, y);
    y += 15;
    doc.fontSize(9).fillColor('black').text(`${settings.company_name}\n${settings.company_address}\nPh: ${settings.support_number}\nEmail: ${settings.support_email}\nGSTIN: ${settings.gstin}`, leftMargin, y);
    y += 50;

    // --- Footer and QR code ---
    doc.fontSize(10).fillColor('black').text(`Tax Invoice No: ${settings.invoice_prefix}-${invoiceNumber}`, leftMargin, y, { align: 'left' });
    y += 15;
    // Generate QR code for invoice number - position it at the right side
    const qrData = await QRCode.toDataURL(`${settings.invoice_prefix}-${invoiceNumber}`);
    doc.image(qrData, pageWidth - rightMargin - 80, y - 10, { width: 80, height: 80 });
    y += 70;
    
    // Use custom footer text if available
    const footerText = settings.invoice_footer_text || 'Thank you for shopping with us.\nIn case you would like to Exchange any of the products purchased, we request you to carry your bill along.';
    doc.fontSize(9).fillColor('black').text(footerText, leftMargin, y, { align: 'left', width: contentWidth - 100 });

    doc.end();

    // Wait for the file to be fully written
    await new Promise((resolve, reject) => {
      stream.on('finish', resolve);
      stream.on('error', reject);
    });

    return filePath;

  } catch (error) {
    console.error('Error generating invoice PDF:', error);
    throw error;
  }
}

module.exports = { generateInvoicePDF }; 
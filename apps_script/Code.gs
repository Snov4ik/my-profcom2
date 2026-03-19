/**
 * Google Apps Script web app for MY_PROFKOM Flutter application.
 *
 * Deployment instructions:
 * 1. Open the Google Sheet: https://docs.google.com/spreadsheets/d/14f89dShxut0tEiBOOwiRLiBtKIspmTr1WryYQ5fSryA
 * 2. Extensions → Apps Script
 * 3. Delete any existing code, paste this entire file into Code.gs
 * 4. Deploy → New deployment → Type: Web app
 *    - Execute as: Me
 *    - Who has access: Anyone
 * 5. Click Deploy, authorize when prompted
 * 6. Copy the Web app URL and paste it into
 *    lib/services/google_sheets_service.dart → _scriptUrl
 */

var SPREADSHEET_ID = '14f89dShxut0tEiBOOwiRLiBtKIspmTr1WryYQ5fSryA';

// Mapping from Flutter model field names to actual sheet column headers
var FIELD_TO_HEADER = {
  'id': 'ID',
  'fullName': 'Ваш повний Піб',
  'recordBookNumber': 'Номер залікової книжки',
  'universityPlace': 'Де ви навчаєтесь?',
  'studyCourse': 'Курс навчання',
  'groupCode': 'Код і номер групи(наприклад РМ-404)',
  'studyForm': 'Ваша форма навчання',
  'paymentVariant': 'Варіант сплати профвнесків',
  'phoneNumber': 'Ваш номер телефону',
  'telegram': 'Ваш телеграм',
  'password': 'Пароль'
};

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var action = data.action;

    if (action === 'addStudent') {
      return addStudent(data.data);
    } else if (action === 'setPassword') {
      return setPassword(data.recordBookNumber, data.password, data.id);
    } else {
      return jsonResponse({ success: false, error: 'Unknown action: ' + action });
    }
  } catch (err) {
    return jsonResponse({ success: false, error: err.toString() });
  }
}

function doGet(e) {
  // Support GET fallback with payload parameter (for CORS workaround)
  if (e && e.parameter && e.parameter.payload) {
    try {
      var data = JSON.parse(e.parameter.payload);
      var action = data.action;

      if (action === 'addStudent') {
        return addStudent(data.data);
      } else if (action === 'setPassword') {
        return setPassword(data.recordBookNumber, data.password, data.id);
      } else {
        return jsonResponse({ success: false, error: 'Unknown action: ' + action });
      }
    } catch (err) {
      return jsonResponse({ success: false, error: err.toString() });
    }
  }
  return jsonResponse({ success: true, message: 'MY_PROFKOM API is running' });
}

function addStudent(studentData) {
  var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  var sheet = ss.getSheets()[0]; // First sheet tab

  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];

  // Find column index for recordBookNumber to check duplicates
  var rbHeader = FIELD_TO_HEADER['recordBookNumber'];
  var rbCol = headers.indexOf(rbHeader);

  if (rbCol >= 0) {
    var allData = sheet.getDataRange().getValues();
    for (var i = 1; i < allData.length; i++) {
      if (String(allData[i][rbCol]).trim() === String(studentData.recordBookNumber).trim()) {
        return jsonResponse({ success: false, error: 'duplicate_record_book' });
      }
    }
  }

  // Build row matching existing column headers
  var row = headers.map(function(header) {
    // Find which Flutter field corresponds to this header
    for (var field in FIELD_TO_HEADER) {
      if (FIELD_TO_HEADER[field] === header) {
        var val = studentData[field];
        if (val === undefined || val === null) return '';
        return String(val);
      }
    }
    return '';
  });

  sheet.appendRow(row);

  return jsonResponse({ success: true, id: studentData.id || '' });
}

function setPassword(recordBookNumber, hashedPassword, newId) {
  var ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  var sheet = ss.getSheets()[0];
  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var allData = sheet.getDataRange().getValues();

  var rbHeader = FIELD_TO_HEADER['recordBookNumber'];
  var pwHeader = FIELD_TO_HEADER['password'];
  var idHeader = FIELD_TO_HEADER['id'];
  var rbCol = headers.indexOf(rbHeader);
  var pwCol = headers.indexOf(pwHeader);
  var idCol = headers.indexOf(idHeader);

  if (rbCol < 0 || pwCol < 0) {
    return jsonResponse({ success: false, error: 'Missing columns in sheet' });
  }

  for (var i = 1; i < allData.length; i++) {
    if (String(allData[i][rbCol]).trim() === String(recordBookNumber).trim()) {
      sheet.getRange(i + 1, pwCol + 1).setValue(hashedPassword);
      // Also set ID if column exists and cell is empty
      if (idCol >= 0 && newId && !String(allData[i][idCol]).trim()) {
        sheet.getRange(i + 1, idCol + 1).setValue(newId);
      }
      return jsonResponse({ success: true });
    }
  }

  return jsonResponse({ success: false, error: 'student_not_found' });
}

function jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

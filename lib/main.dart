
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import 'dart:io';
import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart' as pth;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

List studentResults = [];

List courses = [];
List units = [];
List courseData = [];
List gpa = [];
List averageScores = [];
List<List<dynamic>> gradePoints = [];
List<List<String>> studentGrades = [];
List studentTotalScores = [];
List gradePointScore = [];
List<List<int>> creditObtained = [];
List creditPassed = [];

String username = "";
String institution = "";
String profilePicture = "wStar.jpg";
String sessionToken = "";
bool inProgress = false;
bool returned = false;
String realPath = '';
var db;

int nextPage = 1;

snackMsg(BuildContext context, String msg) {
  var theBar = SnackBar(content: Text(msg), duration: Duration(seconds: 5));
  ScaffoldMessenger.of(context).showSnackBar(theBar);
}

void main() {
  runApp(MyApp());
}

nullInputDialog(BuildContext context, String alertMsg, String alertTitle,
    [bool timed = false, int time = 0]) {
  showDialog(
    context: context,
    builder: (BuildContext contxt) {
      print('object');
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(alertTitle),
            content: Text(alertMsg),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(contxt).pop();
                },
                child: Text("Dismiss"),
              ),
            ],
          );
        },
      );
    },
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Result Processor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //routes: {'/home': (_) => HomeCall(), '/test': (_) => TypeScores(3)},
      //home: ScoreProcessing(2),
      home: Log(),
      //home: Download(),
      //home: CourseData(),
      //home: Test(),
    );
  }
}

class Log extends StatefulWidget {
  @override
  _Log createState() => _Log();
}

//Login page and class of the application
class _Log extends State<Log> {
  var accountDetails;
  bool signal = false;

  preLoad() async {
    await getDatabasesPath().then(
      (value) async {
        realPath = value + 'resultdb.db';

        print(realPath);

        db = await openDatabase(
          realPath,
          version: 1,
          onCreate: (Database db1, int version) {
            db1.execute('''CREATE TABLE resulttb (result_id INTEGER PRIMARY KEY,
           label TEXT, username TEXT, date_modified TEXT,
            student_name TEXT, student_matno TEXT,student_email TEXT, student_scores TEXT,
             total_score TEXT, average_score TEXT, grades TEXT, 
             grade_points TEXT, cgpa TEXT, credit_passed TEXT, 
             credit_failed TEXT)''');

            db1.execute('''CREATE TABLE coursetb (course_id INTEGER PRIMARY KEY,
           label TEXT, username TEXT, date_created TEXT,
            course_title TEXT, course_units TEXT, grade_point_score TEXT,
             total_credit)''');

            db1.execute('''CREATE TABLE usertb (username TEXT PRIMARY KEY,
           password TEXT, institution_name TEXT)''');
          },
        ).then(
          (value) async {
            print('selection commencing');

            await value
                .rawQuery("SELECT label,date_created FROM coursetb")
                .then(
              (value1) {
                print('Details: $value1');
                setState(
                  () {
                    accountDetails = value1;
                    signal = true;
                  },
                );
              },
            );
            return value;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (signal == true) {
      print('preload dusted');

      //accountDetails = getDetails();
      return HomePage(
        newAccount: false,
        accountDetails: accountDetails,
      );
    } else {
      print('preloading');
      preLoad();
      print('awaiting preloading');
      return CircularProgressIndicator(
        strokeWidth: 1,
      );
    }
  }
}

class HomeCall extends StatefulWidget {
  @override
  _HomeCall createState() => _HomeCall();
}

//Login page and class of the application
class _HomeCall extends State<HomeCall> {
  var accountDetails;
  var loadHome;

  getDetails() async {
    print("getdetails called");

    await db.rawQuery("select label,date_created from coursetb").then(
      (value) {
        print(value);
        setState(() {
          accountDetails = value;
          loadHome = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadHome == true)
      return HomePage(
        newAccount: false,
        accountDetails: accountDetails,
      );
    else {
      getDetails();
      return Scaffold(
        body: CircularProgressIndicator(),
      );
    }
  }
}

class HomePage extends StatefulWidget {
  HomePage({required this.newAccount, this.accountDetails: const {}});

  final bool newAccount;
  final accountDetails;

  @override
  _HomePageState createState() =>
      _HomePageState(this.newAccount, this.accountDetails);
}

class _HomePageState extends State<HomePage> {
  _HomePageState(this.newAccount, this.accountDetails);

  final bool newAccount;
  final accountDetails;
  bool goHome = false;
  //bool inProgress = false;

  bool recordsExist = false;
  var records = [];

  viewEditPrintResult(String label, String requestType) async {
    var result = [];

    await db.rawQuery("select * from resulttb where label=?", [label]).then(
      (value) async {
        result.add(value);
        await db.rawQuery(
            "select course_title,course_units,total_credit from coursetb where label=?",
            [label]).then(
          (value) {
            result.add(value);
            print('Value is: $value');
            print('result is: $result');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ViewEditEmailPrintResult(result, requestType),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('inside home');
    //(newAccount == true) ? records = [] : records = accountDetails;
    records = accountDetails;
    print('records loaded');

    if (goHome == true) return HomeCall();
    return Scaffold(
      appBar: AppBar(
        title: Text("ResProc"),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (inProgress == true)
            ? () => null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseData(),
                  ),
                ),
        child: Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: (records.isEmpty)
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.cancel_outlined),
                      Text('No previous results')
                    ],
                  ),
                )
              : Column(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var item in records)
                      Card(
                        child: Column(
                          children: [
                            Text(
                              item['label'],
                            ),
                            Text(
                              item['date_created'].toString().substring(0, 19),
                            ),
                            ButtonBar(
                              alignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    viewEditPrintResult(item['label'], 'edit1');
                                  },
                                  child: Text('Edit'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    viewEditPrintResult(item['label'], 'print');
                                  },
                                  child: Text('Download'),
                                ),
                              ],
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

class CourseData extends StatefulWidget {
  CourseData();
  @override
  _CourseDataState createState() => _CourseDataState();
}

class _CourseDataState extends State<CourseData> {
  var number = '0';
  bool codeValidated = false;
  bool titleValidated = false;
  bool filled = false;
  //bool goHome = false;

  @override
  Widget build(BuildContext context) {
    var credit = List.generate(int.parse(number), (index) => '');
    var courseCode = List.generate(int.parse(number), (index) => '');

    print('number: $number');
    //if (goHome == true) return HomeCall();
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeCall()),
                  (route) => false);
            },
            icon: Icon(Icons.home_outlined),
          ),
        ],
        bottom: PreferredSize(
            child: TextFormField(
              textAlign: TextAlign.center,
              onChanged: (input) {
                if (input.isEmpty)
                  setState(() {
                    number = '0';
                    filled = false;
                  });
                else if (!input.contains(RegExp(r"(\D)"))) {
                  setState(() {
                    number = input;
                    filled = true;
                  });
                }
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.edit),
                filled: true,
                fillColor: Colors.white,
                labelText: "Number of Courses",
                hintText: "How many courses?",
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value!.isEmpty) {
                  number = "0";
                  //return "** required";
                } else if (value.contains(RegExp(r"(\D)"))) {
                  number = "0";
                  //return "Must be a number";
                } else
                  return null;
              },
            ),
            preferredSize: Size.fromHeight(35)),
        title: Text("Course data"),
        centerTitle: true,
      ),
      body: Center(
        heightFactor: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                if (int.parse(number) > 0)
                  DataTable(
                    horizontalMargin: 10,
                    dividerThickness: 5,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(),
                        left: BorderSide(),
                        top: BorderSide(),
                        bottom: BorderSide(),
                      ),
                    ),
                    columnSpacing: 10,
                    columns: [
                      DataColumn(
                        label: Text(
                          (int.parse(number) > 0) ? 's/n' : '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          (int.parse(number) > 0) ? 'Course Code' : '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          (int.parse(number) > 0) ? 'Credit' : '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    rows: [
                      for (var i = 0; i < int.parse(number); i++)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                (i + 1).toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            DataCell(
                              TextFormField(
                                textAlign: TextAlign.center,
                                onChanged: (input) {
                                  courseCode[i] = input;
                                },
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  hintText: "Course?",
                                ),
                                autovalidateMode: AutovalidateMode.always,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    courseCode[i] = '';
                                    //return "**required";
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              TextFormField(
                                textAlign: TextAlign.center,
                                onChanged: (input) {
                                  credit[i] = input;
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Credit?",
                                ),
                                autovalidateMode: AutovalidateMode.always,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    credit[i] = '';
                                    //return "**required";
                                  } else if (value.contains(RegExp(r"(\D)"))) {
                                    credit[i] = '';
                                    //return "Must be a number";
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                if (int.parse(number) > 0)
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: ElevatedButton(
                      onPressed: () {
                        if (courseCode.every((element) => element.isNotEmpty) &&
                            credit.every((element) => element.isNotEmpty)) {
                          print('next called');
                          courses = courseCode;
                          units = credit;
                          courseData.add(courses);
                          courseData.add(units);
                          print(courseData);

                          if (filled)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TypeScores(int.parse(number)),
                              ),
                            );
                        }
                      },
                      child: Text('Next'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TypeScores extends StatefulWidget {
  TypeScores(this.number);
  final int number;
  //final studentResultLength = studentResults.length;
  @override
  _TypeScoresState createState() => _TypeScoresState(this.number);
}

class _TypeScoresState extends State<TypeScores> {
  //_TypeScoresState(this.number, this.studentResultLength);
  _TypeScoresState(this.numOfCourses);
  final numOfCourses;
  var numberOfStudents = '0';

  //final studentResultLength;
  bool codeValidated = false;
  bool titleValidated = false;
  bool filled = false;
  //bool goHome = false;

  @override
  Widget build(BuildContext context) {
    var studentScores = List.generate(
      int.parse(numberOfStudents),
      (index) => List.generate(numOfCourses, (index) => ''),
    );
    var studentData = List.generate(
      int.parse(numberOfStudents),
      (index) => List.generate(2, (index) => ''),
    );

    print('number: $numberOfStudents');

    return Scaffold(
      appBar: AppBar(
        title: Text("Students' Scores"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeCall()),
                  (route) => false);
            },
            icon: Icon(Icons.home_outlined),
          ),
        ],
        bottom: PreferredSize(
          child: TextFormField(
            textAlign: TextAlign.center,
            onChanged: (input) {
              if (input.isEmpty)
                setState(() {
                  numberOfStudents = '0';
                  filled = false;
                });
              else if (!input.contains(RegExp(r"(\D)"))) {
                setState(() {
                  filled = true;
                  numberOfStudents = input;
                });
              }
            },
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.edit),
              filled: true,
              fillColor: Colors.white,
              labelText: "Number of students",
              hintText: "How many students?",
              border: OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.always,
            validator: (value) {
              if (value!.isEmpty) {
                numberOfStudents = "0";
                //return "** required";
              } else if (value.contains(RegExp(r"(\D)"))) {
                numberOfStudents = "0";
                //return "Must be a number";
              } else
                return null;
            },
          ),
          preferredSize: Size.fromHeight(35),
        ),
      ),
      body: Center(
        heightFactor: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                if (int.parse(numberOfStudents) > 0)
                  DataTable(
                    horizontalMargin: 10,
                    dividerThickness: 5,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(),
                        left: BorderSide(),
                        top: BorderSide(),
                        bottom: BorderSide(),
                      ),
                    ),
                    columnSpacing: 10,
                    columns: [
                      DataColumn(
                        label: Text(
                          (int.parse(numberOfStudents) > 0) ? 'S/N' : '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          (int.parse(numberOfStudents) > 0) ? 'NAME' : '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      for (var courseCode in courses)
                        DataColumn(
                          label: Text(
                            (int.parse(numberOfStudents) > 0) ? courseCode : '',
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                    rows: [
                      for (var i = 0; i < int.parse(numberOfStudents); i++)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                (i + 1).toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            DataCell(
                              TextFormField(
                                textAlign: TextAlign.center,
                                onChanged: (input) {
                                  studentData[i][0] = input;
                                  studentData[i][1] = 'mat_num';
                                },
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  hintText: "Name",
                                ),
                                autovalidateMode: AutovalidateMode.always,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    studentData[i][0] = '';
                                    //return "Full name is required";
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ),
                            for (var j = 0; j < numOfCourses; j++)
                              DataCell(
                                TextFormField(
                                  textAlign: TextAlign.center,
                                  onChanged: (input) {
                                    studentScores[i][j] = input;
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: courses[j],
                                  ),
                                  autovalidateMode: AutovalidateMode.always,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      studentScores[i][j] = '';
                                      //return courses[i] + "**required";
                                    } else if (value
                                        .contains(RegExp(r"(\D)"))) {
                                      studentScores[i][j] = '';
                                      //return "Must be a number";
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                if (int.parse(numberOfStudents) > 0)
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: ElevatedButton(
                      onPressed: () {
                        studentResults.clear();
                        if (studentData.every((element) => element
                                .every((element1) => element1.isNotEmpty)) &&
                            studentScores.every((element) => element
                                .every((element1) => element1.isNotEmpty))) {
                          print('next called');
                          for (var k = 0; k < studentData.length; k++) {
                            var x = <dynamic>[];
                            x.addAll(studentData[k]);
                            x.addAll(studentScores[k]);
                            studentResults.add(x);
                          }

                          print('studentData: $studentData');
                          print('studentScores: $studentScores');
                          print('result: $studentResults');

                          if (filled)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScoreProcessing(
                                    int.parse(numberOfStudents), 'typing'),
                              ),
                            );
                        }
                      },
                      child: Text('Next'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreProcessing extends StatefulWidget {
  ScoreProcessing(this.number, this.inputType);
  final String inputType;
  final int number;
  @override
  _ScoreProcessingState createState() =>
      _ScoreProcessingState(this.number, this.inputType);
}

class _ScoreProcessingState extends State<ScoreProcessing> {
  _ScoreProcessingState(this.number, this.inputType);
  final String inputType;
  final int number;
  String label = '';
  totalScores() {
    var resultTotals = [];

    for (List studentRecord in studentResults) {
      var total = 0;

      for (var score = 2; score < studentRecord.length - 2; score++) {
        total += int.parse((studentRecord[score]).toString());
      }
      resultTotals.add(total);
    }
    studentTotalScores = resultTotals;

    for (var i = 0; i < studentResults.length; i++) {
      studentResults[i].add([studentTotalScores[i].toString()]);
    }
  }

  averages() {
    double avgScore;
    for (var i = 0; i < studentTotalScores.length; i++) {
      avgScore = studentTotalScores[i] / (studentResults[0].length - 2);
      averageScores.add(avgScore.toStringAsFixed(2));
    }

    print(averageScores);
    for (var i = 0; i < studentResults.length; i++) {
      studentResults[i].add([averageScores[i].toString()]);
    }
  }

  sortGradePointScores() {
    gradePointScore = [
      ['0', '1', 'F', 0], //[SCORE,GP,GRADE,CF]
      ['45', '2', 'D', 1],
      ['50', '3', 'C', 1],
      ['60', '4', 'B', 1],
      ['70', '5', 'A', 1],
    ]; //sorted sample data

    int val = 0;
    for (var credit in units) val += int.parse(credit);

    courseData.add(gradePointScore);
    courseData.add([val]);
  }

  scoreToPoint() {
    List scoreGrades = gradePointScore;

    List<List<dynamic>> pointList = [];
    List<List<String>> gradeList = [];
    List<List<int>> creditList = [];
    print(scoreGrades);

    for (List studentRecord
        in studentResults) //ie, studentRecord=[jane, matr, emailit,50, 40, 30]
    {
      List<dynamic> points = [];
      List<String> grades = [];
      List<int> creditStatus = [];

      //for (var score in studentRecord[1]) //ie, score=50
      for (var score = 0; score < studentRecord.length - 2; score++) {
        for (var item in scoreGrades) //ie item=[0, 1, 'F',1]
        {
          if (item == scoreGrades.last) {
            if (int.parse((studentRecord[score + 2]).toString()) >=
                int.parse((item[0]).toString())) //ie, if 50>=0
            {
              points.add(item[1]);
              grades.add(item[2]);
              creditStatus.add(item[3]);
              break;
            } else {
              points.add('NaN');
              grades.add('NaN');
              creditStatus.add(0);
              break;
            }
          } else if (int.parse((studentRecord[score + 2]).toString()) >=
                  int.parse((item[0]).toString()) &&
              int.parse((studentRecord[score + 2]).toString()) <
                  int.parse((scoreGrades[scoreGrades.indexOf(item) + 1][0])
                      .toString())) {
            points.add(item[1]);
            grades.add(item[2]);
            creditStatus.add(item[3]);
            break;
          }
        }
      }
      pointList.add(points);
      gradeList.add(grades);
      creditList.add(creditStatus);
    }

    gradePoints = pointList;
    studentGrades = gradeList;
    creditObtained = creditList;

    for (var i = 0; i < studentResults.length; i++) {
      studentResults[i].add(gradePoints[i]);
      print('gradePoints added');
      studentResults[i].add(studentGrades[i]);
      print('grades added');
    }
  }

  cgpa() {
    print('cgpa called');
    print(gradePoints);
    print(units);
    print(studentResults);

    for (var i = 0; i < studentResults.length; i++) {
      print('outer');
      double gp = 0;
      double unitSum = 0;
      int cP = 0;
      for (var j = 0; j < units.length; j++) {
        print('inner');
        gp += int.parse((units[j]).toString()) *
            int.parse((gradePoints[i][j]).toString());
        unitSum += int.parse((units[j]).toString());
        cP += creditObtained[i][j] * int.parse((units[j]).toString());
      }
      gpa.add((gp / unitSum).toStringAsFixed(2));
      creditPassed.add(cP);
    }
    print('computed');

    for (var i = 0; i < studentResults.length; i++) {
      studentResults[i].add([gpa[i].toString()]);
      studentResults[i].add(creditPassed[i]);
    }
    print(studentResults);
  }

  checkLabel(String label) async {
    String status = '';
    await db.rawQuery("SELECT label FROM coursetb").then((value) {
      print(value);
      for (Map item in value) {
        if (item['label'] == label) {
          status = 'exists';
          nullInputDialog(
            context,
            'Label already exists...\nChoose a different label',
            'Invalid',
          );
          break;
        }
      }
      if (status != 'exists') {
        saveResult();
      }
    });
  }

  saveResult() async {
    setState(() {
      inProgress = true;
    });
    print("saveResult called");
    print('Result processing...');
    sortGradePointScores();
    scoreToPoint();
    totalScores();
    averages();
    cgpa();
    print('finished');

    var reply = await db.transaction(
      (trnx) async {
        var pos = 2 + courseData[0].length as int;

        for (List data in studentResults) {
          trnx.rawInsert(
            ''' INSERT INTO resulttb (label,date_modified,username,student_name,
              student_matno,student_email,student_scores,total_score,average_score,
              grades,grade_points,cgpa,credit_passed,credit_failed) values
              (?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
            [
              label, //label
              DateTime.now().toString(), //date_mod
              username, //username
              data[0], //name
              data[1], //matno
              'email', //email
              jsonEncode(data.sublist(2, pos)), //scores
              data[pos + 2][0], //total score
              data[pos + 3][0], //avg score
              jsonEncode(data[pos + 1]), //grades
              jsonEncode(data[pos + 0]), //grade point
              data[pos + 4][0], //cgpa
              data[pos + 5].toString(), //credit passed
              (courseData[3][0] - data[pos + 5]).toString(), //credit failed
            ],
          );
        }
        trnx.rawInsert(
          ''' INSERT INTO coursetb (username,date_created,label,
              course_title,course_units,grade_point_score,total_credit) 
              values (?,?,?,?,?,?,?)''',
          [
            username, //username
            DateTime.now().toString(), //date_creat
            label, //label
            jsonEncode(courseData[0]), //courseCodes
            jsonEncode(courseData[1]), //courseUnits
            jsonEncode(courseData[2]), //grade_point_score
            (courseData[3][0]).toString(), //total_credit
          ],
        );
      },
    ).then((val) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeCall()),
          (route) => false);
    });
    //Database dbl;
    await db.rawQuery("SELECT * FROM resulttb").then((value) => print(value));
    print(reply);
  }

  @override
  Widget build(BuildContext context) {
    sessionToken =
        '7cfb6e5664d3136d06122bdd74192d089838dca74278e85b7e337636869e0066';
    username = 'okon';
    //if (goHome == true) return HomeCall();
    return Scaffold(
        appBar: AppBar(
          title: Text('Result title'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeCall()),
                    (route) => false);
              },
              icon: Icon(Icons.home_outlined),
            ),
          ],
        ),
        body: Container(
          child: Column(
            children: [
              Text(
                "Specify name of the result",
                textAlign: TextAlign.center,
              ),
              TextFormField(
                textAlign: TextAlign.center,
                onChanged: (input) {
                  label = input;
                },
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.edit),
                  labelText: "Result name",
                  hintText: "Result name",
                  border: OutlineInputBorder(),
                ),
                autovalidateMode: AutovalidateMode.always,
                validator: (value) {
                  if (value!.isEmpty) {
                    label = '';
                    return "**required";
                  } else {
                    return null;
                  }
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (label.isNotEmpty) checkLabel(label);
                },
                child: Text('Save result'),
              ),
            ],
          ),
        ));
  }
}

class ViewEditEmailPrintResult extends StatefulWidget {
  ViewEditEmailPrintResult(this.result, this.requestType, {this.index: 0});
  final result;
  final String requestType;
  final int index;
  @override
  _ViewEditEmailPrintResult createState() =>
      _ViewEditEmailPrintResult(this.result, this.requestType,
          index: this.index);
}

class _ViewEditEmailPrintResult extends State<ViewEditEmailPrintResult> {
  _ViewEditEmailPrintResult(this.result, this.requestType, {this.index: 0});
  final result;
  final String requestType;
  final int index;
  var z;
  var allResults = [];
  var resultIds = Set();
  String label = '';

  //bool goHome = false;

  printResult() async {}

  computeChanges(List editedResult, List courseCredits) {
    int i = 0;
    for (Map record in editedResult) {
      List scores = record['student_scores'];
      List grades = [];
      List gp = [];
      int total = 0;
      int cf = 0;
      int cp = 0;
      double gpa = 0.0;
      int j = 0;
      print('in');
      for (String item in scores) {
        if (int.parse(item) < 45) {
          grades.add('F');
          cf += int.parse(courseCredits[j]);
          gpa += (int.parse(courseCredits[j]) * 1);
          gp.add('1');
        } else if (int.parse(item) < 50) {
          grades.add('D');
          cp += int.parse(courseCredits[j]);
          gpa += (int.parse(courseCredits[j]) * 2);
          gp.add('2');
        } else if (int.parse(item) < 60) {
          grades.add('C');
          cp += int.parse(courseCredits[j]);
          gpa += (int.parse(courseCredits[j]) * 3);
          gp.add('3');
        } else if (int.parse(item) < 70) {
          grades.add('B');
          cp += int.parse(courseCredits[j]);
          gpa += (int.parse(courseCredits[j]) * 4);
          gp.add('4');
        } else if (int.parse(item) >= 70) {
          grades.add('A');
          cp += int.parse(courseCredits[j]);
          gpa += (int.parse(courseCredits[j]) * 5);
          gp.add('5');
        }
        print('crossed');
        j++;
        total += int.parse(item);
      }
      print('out');
      editedResult[i]['grades'] = grades;
      editedResult[i]['grade_points'] = gp;
      editedResult[i]['credit_failed'] = cf;
      editedResult[i]['credit_passed'] = cp;
      editedResult[i]['cgpa'] = gpa / (cp + cf);
      editedResult[i]['total_score'] = total;
      editedResult[i]['average_score'] = total / scores.length;

      i++;
    }

    return editedResult;
  }

  saveFile(xlsio.Workbook exc) async {
    print("we're good");
    var doc = exc.saveAsStream(); //;

    FilePicker.platform.getDirectoryPath().then((value) async {
      if (value == null)
        return Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeCall()),
            (route) => false);

      File file = File(pth.join(value, '$label.xlsx'));
      print('file formed');
      if (await Permission.storage.request().isGranted) {
        print("we're in");

        await file.writeAsBytes(doc).then((value) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeCall()),
              (route) => false);
          snackMsg(context, 'saved');
        });
      } else if (await Permission.storage.request().isDenied) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeCall()),
            (route) => false);
        snackMsg(context, 'operation failed');
      }
    });
  }

  createSpreadsheet() {
    xlsio.Workbook excelSheet = new xlsio.Workbook();
    xlsio.Worksheet sheet1 = excelSheet.worksheets[0];

    print('stage1');
    int pos = (jsonDecode(result[1][0]['course_title']).length * 2) + 3;
    print('stage2');
    int titleRows = 5;
    String title =
        "COMPUTER SCIENCE DEPARTMENT,\nFACULTY OF PHYSICAL SCIENCES,\nUNIVERSITY OF BENIN.";

    xlsio.Style _style = excelSheet.styles.add('styles');
    _style.hAlign = xlsio.HAlignType.center;
    _style.vAlign = xlsio.VAlignType.center;
    _style.bold = true;
    _style.fontSize = 12;
    _style.wrapText = true;

    xlsio.Style _style1 = excelSheet.styles.add('styles1');
    _style1.hAlign = xlsio.HAlignType.center;
    _style1.vAlign = xlsio.VAlignType.center;
    _style1.fontSize = 12;

    xlsio.Range _cell;

//titleRows
    _cell = sheet1.getRangeByIndex(1, 1);
    _cell.cellStyle = _style;
    _cell.setText(title);
    //sheet1.getRangeByName('A1:L5').merge();

    sheet1.getRangeByIndex(1, 1, titleRows, pos + 3).merge();
    print('stage3');

//s/n
    _cell = sheet1.getRangeByIndex(titleRows + 1, 1);
    _cell.cellStyle = _style;
    _cell.setText('S/N');
    _cell.autoFit();

//name
    _cell = sheet1.getRangeByIndex(titleRows + 1, 2);
    _cell.cellStyle = _style;
    _cell.setText('NAME');

    //cgpa
    _cell = sheet1.getRangeByIndex(titleRows + 1, pos);
    print('stage4');
    _cell.cellStyle = _style;
    _cell.setText('GPA');
    _cell.autoFit();

    //cf
    _cell = sheet1.getRangeByIndex(titleRows + 1, pos + 1);
    print('stage5');
    _cell.cellStyle = _style;
    _cell.setText('CF');
    _cell.autoFit();

    //cf
    _cell = sheet1.getRangeByIndex(titleRows + 1, pos + 2);
    print('stage6');
    _cell.cellStyle = _style;
    _cell.setText('CP');
    _cell.autoFit();

    //tc
    _cell = sheet1.getRangeByIndex(titleRows + 1, pos + 3);
    print('stage7');
    _cell.cellStyle = _style;
    _cell.setText('TC');
    _cell.autoFit();

    sheet1.getRangeByName('A6:A7').merge();
    sheet1.getRangeByName('B6:B7').merge();
    sheet1.getRangeByIndex(titleRows + 1, pos, titleRows + 2, pos).merge();
    print('stage8');
    sheet1
        .getRangeByIndex(titleRows + 1, pos + 1, titleRows + 2, pos + 1)
        .merge();
    print('stage9');
    sheet1
        .getRangeByIndex(titleRows + 1, pos + 2, titleRows + 2, pos + 2)
        .merge();
    print('stage10');
    sheet1
        .getRangeByIndex(titleRows + 1, pos + 3, titleRows + 2, pos + 3)
        .merge();
    print('stage11');

//for (var title in jsonDecode(result[1][0]['course_title']))

    for (var i = 0, j = 1;
        i < jsonDecode(result[1][0]['course_title']).length;
        i++, j += 2) {
      print('stage12');
      //course credit or load

      _cell = sheet1.getRangeByIndex(titleRows + 1, j + 2);
      _cell.cellStyle = _style;
      _cell.setText(
          jsonDecode(result[1][0]['course_units'])[i].toString().toUpperCase());
      print('stage13');
      //autofit score column
      //_cell.autoFitColumns();
      _cell.columnWidth = 4;
      sheet1.getRangeByIndex(titleRows + 1, j + 3).columnWidth = 4;

      //course code

      _cell = sheet1.getRangeByIndex(titleRows + 2, j + 2);
      _cell.cellStyle = _style;
      print('stage14');
      _cell.setText(
          jsonDecode(result[1][0]['course_title'])[i].toString().toUpperCase());
      print('stage15');
      //_cell.autoFitColumns();

//credit

      sheet1
          .getRangeByIndex(titleRows + 1, j + 2, titleRows + 1, j + 3)
          .merge();
      //x.autoFit();

      //code
      sheet1
          .getRangeByIndex(titleRows + 2, j + 2, titleRows + 2, j + 3)
          .merge();
      //x.autoFit();
    }

    print('stage16');
    for (var i = 0; i < result[0].length; i++) {
      print('stage17');
      //set s/n
      _cell = sheet1.getRangeByIndex(titleRows + i + 3, 1);
      _cell.cellStyle = _style1;
      _cell.setValue(i + 1);
      //set name
      _cell = sheet1.getRangeByIndex(titleRows + i + 3, 2);
      _cell.cellStyle = _style1;
      _cell.setValue(result[0][i]['student_name']);
      print('stage18');
      //set score and grade
      for (int k = 0, j = 3;
          k < jsonDecode(result[0][0]['student_scores']).length;
          k++, j += 2) {
        print('stage19');
        //set score
        _cell = sheet1.getRangeByIndex(titleRows + i + 3, j);
        _cell.cellStyle = _style1;
        print('stage20');
        _cell.setValue(jsonDecode(result[0][i]['student_scores'])[k]);
        print('stage21');
        //set grade
        _cell = sheet1.getRangeByIndex(titleRows + i + 3, j + 1);
        _cell.cellStyle = _style1;
        print('stage22');
        _cell.setValue(jsonDecode(result[0][i]['grades'])[k]);
        print('stage23');
        //autofit grade column
        //_cell.autoFitColumns();
      }

      //set cgpa
      _cell = sheet1.getRangeByIndex(titleRows + i + 3, pos);
      _cell.cellStyle = _style1;
      print('stage24');
      _cell.setValue(result[0][i]['cgpa']);

      //set credits failed
      _cell = sheet1.getRangeByIndex(titleRows + i + 3, pos + 1);
      _cell.cellStyle = _style1;
      _cell.setValue(result[0][i]['credit_failed']);
      print('stage25');

      //set credit passed
      _cell = sheet1.getRangeByIndex(titleRows + i + 3, pos + 2);
      _cell.cellStyle = _style1;
      _cell.setValue(result[0][i]['credit_passed']);
      print('stage26');

      //set total credits
      _cell = sheet1.getRangeByIndex(titleRows + i + 3, pos + 3);
      _cell.cellStyle = _style1;
      _cell.setValue(result[1][0]['total_credit']);
      print('stage27');
    }

    //autofit name column
    sheet1
        .getRangeByIndex(
            titleRows + 1, 2, (titleRows + result[0].length + 2) as int, 2)
        .autoFit();
    print('stage28');

    saveFile(excelSheet);
  }

  saveResult(editedResult) async {
    setState(() {
      inProgress = true;
    });
    print("saveResult called");

    for (var data in editedResult) {
      await db.rawUpdate(
        """update resulttb set label=?,username=?,date_modified=?,
      student_name=?,student_matno=?,student_email=?,student_scores=?,
      total_score=?,average_score=?,grades=?,grade_points=?,cgpa=?,
      credit_failed=?,credit_passed=? where result_id=?""",
        [
          data['label'],
          data['username'],
          DateTime.now().toString(),
          data['student_name'],
          data['student_matno'],
          data['student_email'],
          //jsonEncode(data[7]),
          jsonEncode(data['student_scores']),
          (data['total_score']).toString(),
          (data['average_score']).toString(),
          //jsonEncode(data[10]),
          jsonEncode(data['grades']),
          //jsonEncode(data[11]),
          jsonEncode(data['grade_points']),
          //jsonEncode(data[12]),
          data['cgpa'].toString(),
          data['credit_failed'].toString(),
          data['credit_passed'].toString(),
          data['result_id']
        ],
      ).then(
        (value) {
          print("Successful...");
          snackMsg(context, 'Changes saved!');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('_ViewEditEmailPrintResult called');
    label = result[0][0]['label'];

    for (Map res in result[0]) {
      var x = Map();
      res.forEach(
        (key, value) {
          if (key == 'student_scores') value = jsonDecode(value);
          x[key] = value;
        },
      );
      allResults.add(x);
    }
    print(allResults);

    if (requestType == 'print') {
      createSpreadsheet();
      inProgress = false;
      return Scaffold(
          appBar: AppBar(title: Text('Downloading')),
          body: Text('Downloading'));
    } else if (requestType == 'edit1') {
      inProgress = false;
      return Scaffold(
        appBar: AppBar(
          title: Text(result[0][0]['label']),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeCall()),
                    (route) => false);
              },
              icon: Icon(Icons.home_outlined),
            ),
          ],
        ),
        body: Center(
          heightFactor: 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                child: DataTable(
                  horizontalMargin: 10,
                  dividerThickness: 5,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(),
                      left: BorderSide(),
                      top: BorderSide(),
                      bottom: BorderSide(),
                    ),
                  ),
                  columnSpacing: 10,
                  columns: [
                    DataColumn(
                      label: Center(
                        child: Text(
                          'Name',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    for (var title in jsonDecode(result[1][0]['course_title']))
                      DataColumn(
                        label: Text(
                          title,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                  rows: [
                    for (var k = 0; (k < result[0].length); k++)
                      DataRow(
                        cells: [
                          DataCell(
                            //name
                            TextFormField(
                              textAlign: TextAlign.center,
                              onChanged: (input) {
                                allResults[k]['student_name'] = input;
                                resultIds.add(allResults[k]['result_id']);

                                //for mat_no
                                allResults[k]['student_matno'] = 'email';
                                resultIds.add(allResults[k]['result_id']);

                                //for email
                                allResults[k]['student_email'] = 'email';
                                resultIds.add(allResults[k]['result_id']);
                              },
                              initialValue: result[0][k]['student_name'],
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                hintText: "Name?",
                              ),
                              autovalidateMode: AutovalidateMode.always,
                              validator: (value) {
                                if (value!.isEmpty) {
                                } else
                                  return null;
                              },
                            ),
                          ),
                          for (var t = 0;
                              (t <
                                  jsonDecode(result[0][0]['student_scores'])
                                      .length);
                              t++)
                            DataCell(
                              //Score
                              TextFormField(
                                textAlign: TextAlign.center,
                                onChanged: (input) {
                                  allResults[k]['student_scores'][t] = input;
                                  resultIds.add(allResults[k]['result_id']);
                                },
                                initialValue: jsonDecode(
                                    result[0][k]['student_scores'])[t],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Score?",
                                ),
                                autovalidateMode: AutovalidateMode.always,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    //return "** required";
                                  } else
                                    return null;
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () {
            var finalResult = [];
            for (var res in allResults) {
              if (resultIds.contains(res['result_id'])) {
                finalResult.add(res);
              }
            }
            print(finalResult);

            saveResult(
              computeChanges(
                finalResult,
                jsonDecode(result[1][0]['course_units']),
              ),
            );
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeCall()),
                (route) => false);
          },
        ),
      );
    }
    return Scaffold();
  }
}

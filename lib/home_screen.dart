// IM/2021/043 - Ranaka Fernando

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Key state variables for calculator functionality
  String userInput = ""; // Stores the current user input expression
  String result = "0"; // Stores the calculated result
  String expression = ""; // Stores the original expression for history
  bool isResultShown = false; // Tracks if a result has been displayed

  // List of buttons to be displayed on the calculator
  List<String> buttonList = [
    "AC",
    "( )",
    "%",
    "/",
    "7",
    "8",
    "9",
    "×",
    "4",
    "5",
    "6",
    "-",
    "1",
    "2",
    "3",
    "+",
    "C",
    "0",
    ".",
    "=",
  ];

  // Stores calculation history
  List<String> history = [];

  // Prevents certain characters from being the first input
  List<String> disallowedFirstChars = ['%', '/', '*', '+'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Calculator"),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(
                      history: List<String>.from(history),
                      onClearHistory: () {
                        setState(() {
                          history.clear();
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: resultWidget(),
            ),
            Expanded(
              flex: 3,
              child: buttonWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultWidget() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerRight,
            child: Text(
              userInput,
              style: const TextStyle(fontSize: 26),
              maxLines: 3,
              softWrap: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.centerRight,
            child: Text(
              result,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget buttonWidget() {
    return Container(
      padding: const EdgeInsets.all(30),
      color: const Color.fromARGB(66, 239, 239, 239),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: buttonList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return button(buttonList[index]);
        },
      ),
    );
  }

  Color getColor(String text) {
    if (text == "C") return Colors.redAccent;
    if (text == "=" || text == "AC") return Colors.white;
    if (["-", "+", "/", "×", "( )", "%"].contains(text)) {
      return const Color.fromARGB(255, 0, 142, 6);
    }
    return const Color(0xFF2f2f2f);
  }

  Color getBgColor(String text) {
    if (text == "AC") return Colors.redAccent;
    if (text == "=") return const Color.fromARGB(255, 0, 142, 6);
    return Colors.white;
  }

  Widget button(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          handleButtonPress(text);
        });
      },
      borderRadius: BorderRadius.circular(50),
      child: Ink(
        decoration: BoxDecoration(
          color: getBgColor(text),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 192, 184, 184).withOpacity(0),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: getColor(text),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void handleButtonPress(String text) {
    // Clear all input (AC button)
    if (text == "AC") {
      userInput = "";
      result = "0";
      isResultShown = false;
      return;
    }

    // Delete last character (C button)
    if (text == "C") {
      if (userInput.isNotEmpty) {
        userInput = userInput.substring(0, userInput.length - 1);
      }
      return;
    }

    // Check if current result is an error message
    bool isCurrentError = isErrorMessage(result);

    // Calculate result when = is pressed
    if (text == "=") {
      expression = userInput;
      result = calculate();
      if (!isErrorMessage(result)) {
        // Clean up result formatting
        userInput = result;
        if (userInput.endsWith(".0")) {
          userInput = userInput.replaceAll(".0", "");
        }
        if (result.endsWith(".0")) {
          result = result.replaceAll(".0", "");
        }
        // Add to calculation history
        history.add("$expression = $result");
        isResultShown = true;
      }
      return;
    }

    // Reset input when a new number is entered after an error or result
    if (isResultShown || isCurrentError) {
      if (isNumber(text)) {
        userInput = text;
        result = text;
        isResultShown = false;
        return;
      }
    }

    // Handle bracket input
    if (text == "( )") {
      handleBracketInput();
      return;
    }

    // Convert multiplication symbol to * for parsing
    String effectiveText = text == "×" ? "*" : text;

    // Prevent invalid first characters
    if (userInput.isEmpty && disallowedFirstChars.contains(effectiveText)) {
      return;
    }

    // Prevent consecutive operators
    if (userInput.isNotEmpty) {
      String lastChar = userInput[userInput.length - 1];
      if (_isOperator(lastChar) && _isOperator(effectiveText)) {
        return;
      }
    }

    // Prevent multiple decimal points
    if (text == ".") {
      // Check the last segment of the input for existing decimal point
      List<String> segments = userInput.split(RegExp(r'[+\-*/]'));
      String lastSegment = segments.last;

      // If last segment already contains a decimal, do not allow another
      if (lastSegment.contains(".")) {
        return;
      }
    }

    // Handle different types of input
    if (isNumber(text)) {
      handleNumberInput(text);
    } else if (text == "%") {
      // Calculate percentage
      String percentageExpression = userInput;
      result = calculatePercentage();
      userInput = result;
      history.add("$percentageExpression% = $result");
      isResultShown = true;
    } else {
      // Add operator or other non-number input
      userInput += effectiveText;
      isResultShown = false;
    }
  }

  void handleBracketInput() {
    // Empty input starts with an opening bracket
    if (userInput.isEmpty) {
      userInput += "(";
      return;
    }

    // Get the last character of input
    String lastChar = userInput[userInput.length - 1];

    // Count existing brackets
    int openBrackets = "(".allMatches(userInput).length;
    int closeBrackets = ")".allMatches(userInput).length;

    // Decide whether to add open or close bracket
    if (openBrackets > closeBrackets) {
      // More open brackets, so try to add a closing bracket
      if (_isNumberOrClosingBracket(lastChar)) {
        userInput += ")";
      }
    } else {
      // Decide bracket insertion based on last character
      if (_isOperator(lastChar) || lastChar == "(") {
        userInput += "(";
      } else if (_isNumberOrClosingBracket(lastChar)) {
        // Implicitly multiply before adding a bracket
        userInput += "(";
      } else {
        userInput += "(";
      }
    }
  }

  void handleNumberInput(String number) {
    if (userInput.isEmpty) {
      // First input
      userInput = number == "0" ? "0" : number;
    } else if (userInput == "0") {
      // Replace single zero
      userInput = number == "0" ? "0" : number;
    } else {
      // Insert number, handling special cases like after a closing bracket
      if (userInput.isNotEmpty && userInput[userInput.length - 1] == ")") {
        // Implicitly multiply
        userInput += "*$number";
      } else {
        userInput += number;
      }
    }
  }

  bool isNumber(String text) {
    if (text == ".") return true;
    return double.tryParse(text) != null;
  }

  bool isErrorMessage(String message) {
    return message.startsWith("Error") || message.startsWith("Can't");
  }

  bool _isNumberOrClosingBracket(String char) {
    return RegExp(r'[0-9)]').hasMatch(char);
  }

  bool _isOperator(String char) {
    return ["+", "-", "*", "/", ".", "×", "%"].contains(char);
  }

  String calculate() {
    try {
      // Preprocess input to handle implicit multiplication
      String processedInput = preprocessInput(userInput);

      // Check for division by zero
      if (processedInput.contains("/0")) {
        return "Can't divide by zero";
      }

      // Parse and evaluate the mathematical expression
      var exp = Parser().parse(processedInput);
      var evaluation = exp.evaluate(EvaluationType.REAL, ContextModel());
      return evaluation.toString();
    } catch (e) {
      // Handle any parsing or evaluation errors
      return "Error";
    }
  }

  String preprocessInput(String input) {
    String result = input;

    // Add multiplication between number and opening bracket
    result = result.replaceAllMapped(
      RegExp(r'(\d)(\()'),
      (match) => '${match[1]}*${match[2]}',
    );

    // Add multiplication between closing bracket and number
    result = result.replaceAllMapped(
      RegExp(r'(\))(\d)'),
      (match) => '${match[1]}*${match[2]}',
    );

    // Add multiplication between closing and opening brackets
    result = result.replaceAllMapped(
      RegExp(r'(\))(\()'),
      (match) => '${match[1]}*${match[2]}',
    );

    return result;
  }

  String calculatePercentage() {
    try {
      // Handle percentage in complex expressions
      if (userInput.contains('+') ||
          userInput.contains('-') ||
          userInput.contains('*') ||
          userInput.contains('/')) {
        // Split input into parts
        List<String> parts = userInput.split(RegExp(r'[+\-*/]'));
        if (parts.length > 1) {
          double firstNumber = double.parse(parts[0]);
          double secondNumber = double.parse(parts[1]);
          String operator = userInput.replaceAll(RegExp(r'[0-9.]'), '');

          // Calculate percentage based on operator
          switch (operator) {
            case '+':
              return ((firstNumber * (1 + secondNumber / 100)).toString());
            case '-':
              return ((firstNumber * (1 - secondNumber / 100)).toString());
            case '*':
              return ((firstNumber * secondNumber / 100).toString());
            case '/':
              return ((firstNumber / (secondNumber / 100)).toString());
          }
        }
      }

      // Simple percentage conversion
      double value = double.parse(userInput);
      return (value / 100).toString();
    } catch (e) {
      return "Error";
    }
  }
}

class HistoryScreen extends StatefulWidget {
  final List<String> history;
  final VoidCallback onClearHistory;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.onClearHistory,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final clearButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                int reversedIndex = widget.history.length - 1 - index;
                return ListTile(
                  title: Text(widget.history[reversedIndex]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: clearButtonStyle,
              onPressed: () {
                widget.onClearHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear History'),
            ),
          ),
        ],
      ),
    );
  }
}

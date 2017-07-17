import "dart:html";
import "dart:convert";
import "dart:async";

const String baseUrl = "http://www.hasknowledge.net";
const Map<String, String> paths = const {
  "quizzes": "/quizzes",
  "quiz": "/quiz/",
  "summaries": "/summaries",
  "summary": "/summary/",
  "question": "/question/",
  "answer": "/answer"
};

class QuizCounter {
    int correctCount;
    int totalCount;

    QuizCounter() {
        correctCount = 0;
        totalCount = 0;
    }

    void increment(bool correct, [int weight = 1]) {
        totalCount += weight;
        if (correct) {
            correctCount += weight;
        }
    }

    void correct([int weight = 1]) => increment(true, weight);
    void incorrect([int weight = 1]) => increment(false, weight);

    void reset() {
        correctCount = 0;
        totalCount = 0;
    }

    num fraction() => correctCount/totalCount;
    String percentage() => "${correctCount/totalCount * 100}%";
    String display() => "Total: $totalCount; Correct: $correctCount; Accuracy: ${percentage()}";
}

Future<List<Map>> getQuizList() async {
  var jsonString = await HttpRequest.getString(baseUrl + paths["quizzes"]);
  return JSON.decode(jsonString);
}

Future<Map> getQuiz(int id) async {
  var jsonString =
      await HttpRequest.getString(baseUrl + paths["quiz"] + id.toString());
  return JSON.decode(jsonString);
}

Future loadQuiz(int id, Element quizElement) async {
  Map quiz = await getQuiz(id);
  quizElement.children = [];
  if (quiz["maybequiz"] == null) {
    quizElement.text = "Could not load quiz with ID ${quiz['id']}";
  } else {
    var quizDetails = quiz["maybequiz"];
    QuizCounter counter = new QuizCounter();
    var quizDisplay = new UListElement()
      ..text = "${quizDetails['title']} (${quizDetails['topic']})";
    List<Map> questions = quiz["questions"];
    questions.forEach((question) {
      var output = new LIElement();
      var inner = new UListElement()..text = "${question['question']}";
      question["answers"].forEach((answer) {
        var answerElem = new LIElement()..text = answer["content"];
        answerElem.onClick.listen((_) {
          answerElem.text += " ${answer['correct'] ? 'Correct!' : 'Incorrect'}";
          counter.increment(answer["correct"]);
        });
        inner.children.add(answerElem);
      });
      output.children = [inner];
      quizDisplay.children.add(output);
    });
    quizElement.children = [quizDisplay];
    var scoreContainer = new DivElement();
    var scoreDisplay = new SpanElement();
    var scoreButton = new InputElement()
        ..type = "button"
        ..value = "Show Score"
        ..onClick.listen((_) {scoreDisplay.text = counter.display();});
    scoreContainer.children = [scoreButton, scoreDisplay];
    quizElement.children.add(scoreContainer);
    var reloadButton = new InputElement()
        ..type = "button"
        ..value = "Refresh quiz"
        ..onClick.listen((_) {loadQuiz(id, quizElement);});
    quizElement.children.add(reloadButton);
    var questionFormElement = new DivElement();
    quizElement.children.add(questionFormElement);
    createQuestionForm(questionFormElement, quizElement, id);
  }
}

Future setupQuizzes(Element quizElement) async {
  var quizzes = await getQuizList();
  var quizList = new UListElement();
  quizzes.forEach((quiz) {
    var listItem = new LIElement();
    listItem.text =
        "Title: ${quiz['title']} User ID: ${quiz['userId']} Public: ${quiz['publicAccess'] ? 'Yes' : 'No'}";
    listItem.onClick.listen((_) {
      loadQuiz(quiz["id"], quizElement);
    });
    quizList.children.add(listItem);
  });
  quizElement.children = [quizList];
}

Future postQuiz(Map quiz) async {
  var req = new HttpRequest();
  req.open("POST", baseUrl + paths["quizzes"]);
  req.onReadyStateChange.listen((_) {
    print(req.responseText);
  });
  print(JSON.encode(quiz));
  req.send(JSON.encode(quiz));
}

Future handleQuizForm(
    InputElement title, InputElement topic, InputElement publicAccess) async {
  Map quizData = {
    "title": title.value,
    "topic": topic.value,
    "publicAccess": publicAccess.checked,
    "userId": 0,
    "id": 0
  };
  print("Quiz Data: $quizData");
  postQuiz(quizData);
}

Future setupQuizForm(Element quizFormElement, Element quizzesElement) async {
  var inputs = [
    new InputElement()
      ..type = "text"
      ..placeholder = "Title",
    new InputElement()
      ..type = "text"
      ..placeholder = "Topic",
    new InputElement()..type = "checkbox"
  ];
  var submitButton = new InputElement()
    ..type = "button"
    ..value = "Submit"
    ..onClick.listen((_) async {
      await handleQuizForm(inputs[0], inputs[1], inputs[2]);
      setupQuizzes(quizzesElement);
    });
  quizFormElement.children = inputs;
  quizFormElement.children.add(submitButton);
}

Future createAnswers(List<Element> answerElems, int questionId) async {
  var answers = answerElems.map((elem) {
    Map answerData = {
      "content": elem.children[0].value,
      "correct": elem.children[2].checked,
      "questionId": questionId
    };
    return answerData;
  }).toList();
  var req = new HttpRequest();
  req.open("POST", baseUrl + paths["answer"]);
  req.onReadyStateChange.listen((_) {
    print(req.responseText);
  });
  print(JSON.encode(answers));
  req.send(JSON.encode(answers));
}

Future createQuestion(
    InputElement questionElem, Element answerContainer, int quizId) async {
  Map question = {"question": questionElem.value, "quizId": quizId};
  var req = new HttpRequest();
  req.open("POST", baseUrl + paths["question"] + quizId.toString());
  req.onReadyStateChange.listen((_) {
    print("Response to Question POST: " + req.responseText);
    if (req.readyState == 4) {
        print("Convering result ${req.responseText} to JSON");
        var questionId = JSON.decode(req.responseText);
        print("Question ID: $questionId");
        createAnswers(answerContainer.children, questionId);
    }
  });
  print(JSON.encode(question));
  req.send(JSON.encode(question));
}

Future<List<InputElement>> addAnswerElement(Element targetElement) async {
  DivElement container = new DivElement();
  InputElement contentElem = new InputElement()
    ..type = "text"
    ..placeholder = "Answer Content";
  SpanElement correctLabel = new SpanElement()..text = "Correct? ";
  InputElement correctElem = new InputElement()..type = "checkbox";
  InputElement removeElem = new InputElement()
    ..type = "button"
    ..value = "Remove answer"
    ..onClick.listen((_) {
      targetElement.children.remove(container);
    });
  container.children = [contentElem, correctLabel, correctElem, removeElem];
  targetElement.children.add(container);
  return [contentElem, correctElem];
}

Future createQuestionForm(Element targetElement, Element quizElement, int quizId) async {
  InputElement questionField = new InputElement()
    ..type = "text"
    ..placeholder = "Question Text";
  DivElement answerFields = new DivElement();
  for (var i = 0; i < 4; ++i) {
    addAnswerElement(answerFields);
  }
  InputElement addAnswerField = new InputElement()
      ..type = "button"
      ..value = "Add Answer"
      ..onClick.listen((_) {addAnswerElement(answerFields);});
  InputElement submit = new InputElement()
    ..type = "button"
    ..value = "Submit"
    ..onClick.listen((_) {
      createQuestion(questionField, answerFields, quizId);
    });
  targetElement.children = [questionField, addAnswerField, answerFields, submit];
}

void runQuizzes(Element target) {
  var quizElem = new DivElement();
  var formElem = new DivElement();
  var elem = new DivElement()
    ..text = "Load quizzes"
    ..onClick.listen((_) {
      setupQuizzes(quizElem);
    });
  target.children = [elem, formElem, quizElem];
  setupQuizForm(formElem, quizElem);
}

import "dart:html";
import "dart:convert";
import "dart:async";

const String baseUrl = "http://www.hasknowledge.net";
const Map<String, String> paths = const {
  "quizzes": "/quizzes",
  "quiz": "/quiz/",
  "summaries": "/summaries",
  "summary": "/summary/"
};

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
  if (quiz["maybequiz"] == null) {
    quizElement.text = "Could not load quiz with ID ${quiz['id']}";
  } else {
    var quizDetails = quiz["maybequiz"];
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
        });
        inner.children.add(answerElem);
      });
      output.children = [inner];
      quizDisplay.children.add(output);
    });
    quizElement.children = [quizDisplay];
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
  req.send(quiz);
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

Future setupQuizForm(Element quizFormElement) async {
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
    ..onClick.listen((_) {
      handleQuizForm(inputs[0], inputs[1], inputs[2]);
    });
  quizFormElement.children = inputs;
  quizFormElement.children.add(submitButton);
}

void main() {
  var quizElem = new DivElement();
  var formElem = new DivElement();
  var elem = new DivElement()
    ..text = "Load quizzes"
    ..onClick.listen((_) {
      setupQuizzes(quizElem);
    });
  document.body.children..add(elem)..add(formElem)..add(quizElem);
  setupQuizForm(formElem);
}

import "dart:html";
import "dart:convert";
import "dart:async";
import "generic.dart";

const String baseUrl = "";
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

  num fraction() => correctCount / totalCount;
  String percentage() => "${correctCount/totalCount * 100}%";
  String display() =>
      "Total: $totalCount; Correct: $correctCount; Accuracy: ${percentage()}";
}

Future<List<Map>> getQuizList() async {
  String jsonString = await HttpRequest.getString(baseUrl + paths["quizzes"]);
  return JSON.decode(jsonString);
}

Future<Map> getQuiz(int id) async {
  String jsonString =
      await HttpRequest.getString(baseUrl + paths["quiz"] + id.toString());
  return JSON.decode(jsonString);
}

Future deleteQuiz(int id, Element quizElement) async {
  HttpRequest req = new HttpRequest();
  req.open("DELETE", baseUrl + paths["quiz"] + id.toString());
  req.send();
  setupQuizzes(quizElement);
}

Future loadQuiz(int id, Element quizElement) async {
  Map quiz = await getQuiz(id);
  quizElement.children = [];
  if (quiz["maybequiz"] == null) {
    quizElement.text = "Could not load quiz with ID ${quiz['id']}";
  } else {
    Map quizDetails = quiz["maybequiz"];
    QuizCounter counter = new QuizCounter();
    UListElement quizDisplay = new UListElement()
      ..classes.add("quiz")
      ..text = "${quizDetails['title']} (${quizDetails['topic']})";
    List<Map> questions = quiz["questions"];
    questions.forEach((question) {
      LIElement output = new LIElement();
      UListElement inner = new UListElement()
        ..text = "${question['question']}"
        ..classes.add("question");
      question["answers"].forEach((answer) {
        LIElement answerElem = new LIElement()..text = answer["content"];
        SpanElement answerCorrect = new SpanElement()
          ..text = "${answer['correct'] ? 'Correct!' : 'Incorrect'}"
          ..classes.add("answer${answer['correct'] ? 'Correct' : 'Incorrect'}")
          ..classes.add("answerNotice");
        answerElem.onClick.listen((_) {
          if (!answerElem.children.contains(answerCorrect)) {
            answerElem.children.add(answerCorrect);
          }
          counter.increment(answer["correct"]);
        });
        inner.children.add(answerElem);
      });
      output.children = [inner];
      quizDisplay.children.add(output);
    });
    quizElement.children = [quizDisplay];
    DivElement scoreContainer = new DivElement()
      ..classes.add("quizScoreContainer");
    SpanElement scoreDisplay = new SpanElement()..classes.add("quizScore");
    InputElement scoreButton = new InputElement()
      ..type = "button"
      ..value = "Show Score"
      ..classes.add("quizScoreButton")
      ..onClick.listen((_) {
        scoreDisplay.text = counter.display();
      });
    scoreContainer.children = [scoreButton, scoreDisplay];
    quizElement.children.add(scoreContainer);
    InputElement reloadButton = new InputElement()
      ..type = "button"
      ..value = "Refresh quiz"
      ..classes.add("quizReload")
      ..onClick.listen((_) {
        loadQuiz(id, quizElement);
      });
    quizElement.children.add(reloadButton);
    if (quiz["owner"]) {
      DivElement questionFormElement = new DivElement()
        ..classes.add("questionForm");
      quizElement.children.add(questionFormElement);
      createQuestionForm(questionFormElement, quizElement, id);

      /* var deleteContainer = new DivElement()..classes.add("deleteQuizContainer");
      var deleteButton = new InputElement()
          ..type = "button"
          ..classes.add("deleteQuiz")
          ..value = "Delete Quiz";
      var deleteConfirm = new InputElement()
          ..type = "button"
          ..classes.add("deleteQuizConfirm")
          ..value = "Confirm"
          ..onClick.listen((_) {deleteQuiz(id, quizElement);});
      var deleteCancel = new InputElement()
          ..type = "button"
          ..classes.add("deleteQuizCancel")
          ..value = "Cancel";
      deleteCancel.onClick.listen((_) {deleteContainer.children.remove(deleteConfirm); deleteContainer.children.remove(deleteCancel);});
      deleteButton.onClick.listen((_) {deleteContainer.children.add(deleteConfirm); deleteContainer.children.add(deleteCancel);});
      deleteContainer.children = [deleteButton];

      quizElement.children.add(deleteContainer); */
    }
  }
}

Future setupQuizzes(Element quizElement) async {
  List<Map> quizzes = await getQuizList();
  DivElement quizInner = new DivElement();
  UListElement quizList = new UListElement()..classes.add("quizzes");
  quizzes.forEach((quiz) {
    LIElement listItem = new LIElement()..classes.add("quizListing");
    listItem.text = "${quiz['title']} (${quiz['topic']})";
    listItem.onClick.listen((_) {
      loadQuiz(quiz["id"], quizInner);
    });
    quizList.children.add(listItem);
  });
  Set<String> quizTopics =
      quizzes.map((quiz) => quiz["topic"]).toSet(); // Ensures uniqueness
  UListElement filterButtons = new UListElement()..classes.add("filters");
  filterButtons.children = quizTopics
      .map((topic) => new LIElement()
        ..classes.add("filter")
        ..children.add(new InputElement()
          ..type = "button"
          ..value = topic
          ..onClick.listen((_) {
            setupFilteredQuizzes(quizInner, topic);
          })))
      .toList();
  quizInner.children = [quizList];
  quizElement.children = [filterButtons, quizInner];
}

Future setupFilteredQuizzes(Element quizElement, String topic) async {
  List<Map> quizzes = await getFiltered(Routes.quizzes(topic));
  UListElement quizList = new UListElement()..classes.add("quizzes");
  for (Map quiz in quizzes) {
    LIElement listItem = new LIElement()
      ..classes.add("quizListing")
      ..text = "${quiz['title']} (${quiz['topic']})"
      ..onClick.listen((_) {
        loadQuiz(quiz["id"], quizElement);
      });
    quizList.children.add(listItem);
  }
  quizElement.children = [quizList];
}

Future postQuiz(Map quiz) async {
  HttpRequest req = new HttpRequest();
  req.open("POST", baseUrl + paths["quizzes"]);
  req.onReadyStateChange.listen((_) {
    print(req.responseText);
  });
  print(JSON.encode(quiz));
  req.send(JSON.encode(quiz));
}

Future handleQuizForm(
    InputElement title, InputElement topic, InputElement publicAccess) async {
  Map<String, dynamic> quizData = {
    "title": title.value,
    "topic": topic.value,
    "publicAccess": publicAccess.checked,
    "userId": 0,
    "id": 0
  };
  title.value = "";
  topic.value = "";
  publicAccess.checked = false;
  print("Quiz Data: $quizData");
  postQuiz(quizData);
}

Future setupQuizForm(Element quizFormElement, Element quizzesElement) async {
  ParagraphElement description = new ParagraphElement()..text = "Create a Quiz";
  List<Element> inputs = [
    description,
    new InputElement()
      ..type = "text"
      ..classes.add("quizTitleInput")
      ..classes.add("quizFormInput")
      ..placeholder = "Title",
    new InputElement()
      ..type = "text"
      ..classes.add("quizTopicInput")
      ..classes.add("quizFormInput")
      ..placeholder = "Topic",
    new SpanElement()
      ..text = "Public? "
      ..children.add(new InputElement()
        ..type = "checkbox"
        ..classes.add("quizPublicInput"))
  ];
  InputElement submitButton = new InputElement()
    ..type = "button"
    ..value = "Submit"
    ..classes.add("quizSubmitInput")
    ..classes.add("submit")
    ..onClick.listen((_) async {
      await handleQuizForm(inputs[1], inputs[2], inputs[3].children[0]);
      setupQuizzes(quizzesElement);
    });
  quizFormElement.children = inputs;
  quizFormElement.children.add(submitButton);
}

Future createAnswers(List<Element> answerElems, int questionId) async {
  List<Map<String, dynamic>> answers = answerElems
      .map((elem) => {
            "content": elem.children[0].value,
            "correct": elem.children[2].checked,
            "questionId": questionId
          })
      .toList();
  HttpRequest req = new HttpRequest();
  req.open("POST", baseUrl + paths["answer"]);
  req.onReadyStateChange.listen((_) {
    print(req.responseText);
  });
  print(JSON.encode(answers));
  req.send(JSON.encode(answers));
  for (Element answerElem in answerElems) {
    answerElem.children[0].value = "";
    answerElem.children[2].checked = false;
  }
}

Future createQuestion(
    InputElement questionElem, Element answerContainer, int quizId) async {
  Map question = {"question": questionElem.value, "quizId": quizId};
  questionElem.value = "";
  HttpRequest req = new HttpRequest();
  req.open("POST", baseUrl + paths["question"] + quizId.toString());
  req.onReadyStateChange.listen((_) {
    print("Response to Question POST: " + req.responseText);
    if (req.readyState == 4) {
      print("Convering result ${req.responseText} to JSON");
      int questionId = JSON.decode(req.responseText);
      print("Question ID: $questionId");
      createAnswers(answerContainer.children, questionId);
    }
  });
  print(JSON.encode(question));
  req.send(JSON.encode(question));
}

Future<List<InputElement>> addAnswerElement(Element targetElement) async {
  DivElement container = new DivElement()..classes.add("answerFieldsContainer");
  InputElement contentElem = new InputElement()
    ..type = "text"
    ..classes.add("answerContentInput")
    ..placeholder = "Answer Content";
  SpanElement correctLabel = new SpanElement()
    ..text = "Correct? "
    ..classes.add("answerCorrectFieldLabel");
  InputElement correctElem = new InputElement()
    ..type = "checkbox"
    ..classes.add("answerCorrectField");
  InputElement removeElem = new InputElement()
    ..type = "button"
    ..value = "Remove answer"
    ..classes.add("answerRemoveButton")
    ..onClick.listen((_) {
      targetElement.children.remove(container);
    });
  container.children = [contentElem, correctLabel, correctElem, removeElem];
  targetElement.children.add(container);
  return [contentElem, correctElem];
}

Future createQuestionForm(
    Element targetElement, Element quizElement, int quizId) async {
  InputElement questionField = new InputElement()
    ..type = "text"
    ..classes.add("questionField")
    ..placeholder = "Question Text";
  DivElement answerFields = new DivElement()..classes.add("answerFields");
  for (int i = 0; i < 4; ++i) {
    addAnswerElement(answerFields);
  }
  InputElement addAnswerField = new InputElement()
    ..type = "button"
    ..value = "Add Answer"
    ..classes.add("addAnswerButton")
    ..onClick.listen((_) {
      addAnswerElement(answerFields);
    });
  InputElement submit = new InputElement()
    ..type = "button"
    ..value = "Submit"
    ..classes.add("questionSubmitInput")
    ..classes.add("submit")
    ..onClick.listen((_) {
      createQuestion(questionField, answerFields, quizId);
    });
  targetElement.children = [
    questionField,
    addAnswerField,
    answerFields,
    submit
  ];
}

Future runQuizzes(Element target) async {
  DivElement quizElem = new DivElement();
  DivElement formElem = new DivElement()..classes.add("quizForm");
  InputElement elem = new InputElement()
    ..type = "button"
    ..value = "Load quizzes"
    ..classes.add("loadQuizzes")
    ..onClick.listen((_) {
      setupQuizzes(quizElem);
    });
  target.children =
      (await isLoggedIn()) ? [elem, formElem, quizElem] : [elem, quizElem];
  setupQuizForm(formElem, quizElem);
}

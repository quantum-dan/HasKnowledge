import "dart:html";
import "dart:convert";
import "dart:async";

const String baseUrl = "http://hasknowledge.net";
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
    var jsonString = await HttpRequest.getString(baseUrl + paths["quiz"] + id.toString());
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
            output.innerHtml = "${question['question']}<br />"
                "${question['answers']}";
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
        listItem.text = "Title: ${quiz['title']} User ID: ${quiz['userId']} Public: ${quiz['publicAccess'] ? 'Yes' : 'No'}";
        listItem.onClick.listen((_) {loadQuiz(quiz["id"], quizElement);});
        quizList.children.add(listItem);
    });
    quizElement.children = [quizList];
}

void main() {
    var quizElem = new DivElement();
    var elem = new DivElement()
        ..text = "Load quizzes"
        ..onClick.listen((_) {setupQuizzes(quizElem);});
    document.body.children
        ..add(elem)
        ..add(quizElem);
}

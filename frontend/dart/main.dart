import "summary.dart";
import "quiz.dart";
import "dart:html";

void main() {
    Element target = new DivElement();
    InputElement summariesButton = new InputElement()
        ..type = "button"
        ..value = "Summaries"
        ..onClick.listen((_) {runSummaries(target);});
    InputElement quizzesButton = new InputElement()
        ..type = "button"
        ..value = "Quizzes"
        ..onClick.listen((_) {runQuizzes(target);});
    document.body.children = [quizzesButton, summariesButton, target];
}

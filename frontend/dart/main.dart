import "summary.dart";
import "quiz.dart";
import "generic.dart";
import "dart:html";

void main() {
  Element buttonContainer = new DivElement()
    ..classes.add("dartnavbar");
  Element target = new DivElement();
  InputElement summariesButton = new InputElement()
    ..type = "button"
    ..value = "Summaries"
    ..classes.add("summariesSelect")
    ..classes.add("dartnav")
    ..onClick.listen((_) {
      runSummaries(target);
    });
  InputElement quizzesButton = new InputElement()
    ..type = "button"
    ..value = "Quizzes"
    ..classes.add("quizzesSelect")
    ..classes.add("dartnav")
    ..onClick.listen((_) {
      runQuizzes(target);
    });
  buttonContainer.children = [quizzesButton, summariesButton];
  document.body.children = [buttonContainer, target];
}

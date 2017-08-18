import "summary.dart";
import "quiz.dart";
import "generic.dart";
import "dart:html";
import "dart:async";
import "dart:convert";

main() async {
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
  document.body.children = [buttonContainer, target, await loginButton()];
}

Future<Element> loginButton() async {
    String loginUrl = "/auth/page/googleemail2/forward";
    String logoutUrl = "/auth/logout";
    bool isLoggedIn = JSON.decode(await HttpRequest.getString("/check"))["auth"];
    Element authButton = new InputElement()
        ..type = "button"
        ..value = isLoggedIn ? "Log Out" : "Log In"
        ..onClick.listen((_) => window.location.href = isLoggedIn ? logoutUrl : loginUrl);
    return authButton;
}

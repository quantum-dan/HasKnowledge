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
  introParagraph.children.add(new InputElement()
          ..type = "button"
          ..value = "Really love HasKnowledge?"
          ..onClick.listen((_) {
              introParagraph.children.add(donateText);
              introParagraph.children.add(donateLink);
          }));
  target.children = [introParagraph];
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

Element donateLink = new AnchorElement()
    ..classes.add("donate")
    ..text = "PayPal"
    ..href = "https://paypal.me/DPhilippus";

Element donateText = new SpanElement()
    ..classes.add("donate")
    ..text = "HasKnowledge is free, but running it isn't.  Right now it costs less than \$10/month to run, but that will go up with more users, and if there's extra the developer (who works for free) wouldn't mind getting a paycheck!  Here's the link: ";

Element introParagraph = new DivElement()
    ..classes.add("intro")
    ..text = "Welcome to HasKnowledge!  Here, you can record what you learn in quizzes (built up over time, or all at once) and summaries, then come back and study efficiently later.  It's all free, and with a Google account login you don't have to worry about remembering yet another password.  Just hit the log in button down there and start studying, or don't and use public content others have published. ";

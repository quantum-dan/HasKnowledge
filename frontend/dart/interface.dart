/// Interface to the server.

import "dart:async";
import "dart:convert";
import "dart:html";

class Routes {
  static String home = "/";
  static String quizzes = "/quizzes";
  static String quiz(int id) => "/quiz/$id";
  static String questionPost(int quizId) => "/question/$quizId";
  static String answerPost = "/answer";

  static String summaries = "/summaries";
}

class GetRequests {
  static Future<List<QuizInfo>> quizzes() async {
    String jsonString = await HttpRequest.getString(Routes.quizzes);
    List<Map> jsonMap = JSON.decode(jsonString);
    return jsonMap.map((quiz) => new QuizInfo.fromJSON(quiz)).toList();
  }

  static Future<FullQuiz> quiz(int id) async => new FullQuiz.fromJSON(
      JSON.decode(await HttpRequest.getString(Routes.quiz(id))));

  static Future<List<Summary>> summaries() async => JSON.decode(await HttpRequest.getString(Routes.summaries)).map((summary) => new Summary.fromJSON(summary)).toList();
}

class PostRequests {
    static Future<String> json(String data, String url) async {
        HttpRequest req = new HttpRequest();
        req.open("POST", url);
        req.send(data);
        while (true)
            if (req.readyState == 4) return req.responseText;
    }

    static Future quiz(PostQuiz data) async => PostRequests.json(data.toJSON(), Routes.quizzes);
    static Future question(Question data, int quizId) async {
        String questionIdJson = await PostRequests.json(data.toJSON(), Routes.questionPost(quizId));
        int questionId = JSON.decode(quizIdJson);

class PostQuiz {
    String topic;
    String title;
    bool publicAccess;

    String toJSON() => JSON.encode(Map {
        "topic": this.topic,
        "title": this.title,
        "userId": 0,
        "id": 0,
        "publicAccess": this.publicAccess
    });

    PostQuiz(this.title, this.topic, this.publicAccess);
}

class Quiz {
  String topic;
  String title;
  int userId;
  Quiz(this.title, this.topic, this.userId);
}

class QuizInfo {
  int quizId;
  Quiz quiz;
  QuizInfo(this.quizId, this.quiz);
  QuizInfo.fromJSON(Map json) {
    this.quizId = json["id"];
    this.quiz = new Quiz(json["title"], json["topic"], json["userId"]);
  }
}

class Answer {
  bool correct;
  int questionId;
  String content;
  Answer(this.content, this.correct, this.questionId);
  Answer.fromJSON(Map json) {
    this.correct = json["correct"];
    this.content = json["content"];
    this.questionId = json["questionId"];
  }

  String toJSON() => JSON.encode(Map {
      "correct": this.correct,
      "content": this.content,
      "questionId": this.questionId
  });
}

class Question {
  String question;
  List<Answer> answers;
  Question(this.question, this.answers);
  Question.fromJSON(Map json) {
    this.question = json["question"];
    this.answers =
        json["answers"].map((answer) => new Answer.fromJSON(answer)).toList();
  }

  String toJSON() => JSON.encode(Map {
      "question": this.question,
      "quizId": 0
  });
}

class FullQuiz {
  List<Question> questions;
  bool ownedByUser;
  QuizInfo quiz;
  FullQuiz(this.quiz, this.ownedByUser, this.questions);
  FullQuiz.fromJSON(Map json) {
    this.questions = json["questions"]
        .map((question) => new Question.fromJSON(question))
        .toList();
    this.ownedByUser = json["owner"];
    json["maybequiz"]["id"] = json["id"];
    this.quiz = new QuizInfo.fromJSON(json["maybequiz"]);
  }
}

class Summary {
  String topic;
  String title;
  String content;
  Summary(this.title, this.topic, this.content);
  Summary.fromJSON(Map json): this(json["title"], json["topic"], json["content"]);
}

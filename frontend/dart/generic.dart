import "dart:async";
import "dart:convert";
import "dart:html";

class Routes {
    static String quizzes(String topic) => "/quizzes/$topic";
    static String summaries(String topic) => "/summaries/$topic";
}

Future<List<Map>> getFiltered(String path) async => JSON.decode(await HttpRequest.getString(path));

// Functions for working with quizzes

function updateQuizList(handler) { // Handler receives a list of quizzes
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "http://www.hasknowledge.net/quizzes", true);
    xhr.onreadystatechange = function() {
        var result = xhr.responseText;
        var quizzes = JSON.parse(result);
        handler(quizzes);
    }
    xhr.send();
}

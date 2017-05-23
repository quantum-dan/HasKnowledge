module Handler.Quiz where

import Import
import Yesod.Form.Jquery

data FormQuiz = FormQuiz {
  fqTitle :: Text,
  fqTopic :: Text,
  fqPublic :: Bool
}

data FormQuestion = FormQuestion {
  fqQuestion :: Text,
  fqAnswer1 :: Text, fqAnswer1C :: Bool,
  fqAnswer2 :: Text, fqAnswer2C :: Bool,
  fqAnswer3 :: Text, fqAnswer3C :: Bool,
  fqAnswer4 :: Text, fqAnswer4C :: Bool
}

createQuestionForm :: Html -> MForm Handler (FormResult FormQuestion, Widget)
createQuestionForm = renderDivs $ FormQuestion
  <$> areq textField "Question" Nothing
  <*> areq textField "Answer 1" Nothing
  <*> areq checkBoxField "Correct?" Nothing
  <*> areq textField "Answer 2" Nothing
  <*> areq checkBoxField "Correct?" Nothing
  <*> areq textField "Answer 3" Nothing
  <*> areq checkBoxField "Correct?" Nothing
  <*> areq textField "Answer 4" Nothing
  <*> areq checkBoxField "Correct?" Nothing

createQuestion :: FormResult FormQuestion -> Key Quiz -> HandlerT App IO ()
createQuestion formResult qId =
  case formResult of
    FormSuccess (FormQuestion question a1 c1 a2 c2 a3 c3 a4 c4) -> runDB $ do
        questionId <- insert (Question qId question)
        _ <- insert (Answer questionId a1 c1)
        _ <- insert (Answer questionId a2 c2)
        _ <- insert (Answer questionId a3 c3)
        _ <- insert (Answer questionId a4 c4)
        return ()
    _ -> return ()

createQuizForm :: Html -> MForm Handler (FormResult FormQuiz, Widget)
createQuizForm = renderDivs $ FormQuiz
  <$> areq textField "Title" Nothing
  <*> areq textField "Topic" Nothing
  <*> areq checkBoxField "Public" Nothing

createQuiz :: FormResult FormQuiz -> Key User -> HandlerT App IO ()
createQuiz formResult userId =
  case formResult of
    FormSuccess (FormQuiz title topic public) -> do
      _ <- runDB $ insert (Quiz title userId topic public)
      return ()
    _ -> return ()

getQuizzesR :: Handler Html
getQuizzesR = do
  mAuth <- maybeAuth
  (quizForm, enctype) <- generateFormPost createQuizForm
  case mAuth of
    Nothing -> redirect HomeR
    Just auth -> do
      quizzes <- getAvailableQuizzes $ entityKey auth
      defaultLayout $ do
        setTitle "Quizzes"
        $(widgetFile "quizlist")

postMkQuizR :: Handler Html
postMkQuizR = do
  ((result, _), _) <- runFormPost createQuizForm
  mAuth <- maybeAuth
  case mAuth of
    Just auth -> do
      createQuiz result (entityKey auth)
      redirect QuizzesR
    Nothing -> redirect HomeR

getQuizR :: Key Quiz -> Handler Html
getQuizR qId = do
  (questionForm, enctype) <- generateFormPost createQuestionForm
  questions <- getQuestions qId
  defaultLayout $ do
    toWidget [julius|
                    function correct(c) {
                      alert(c);
                    }
                    |]
    setTitle "Quiz"
    $(widgetFile "quiz")

postQuestionR :: Key Quiz -> Handler Html
postQuestionR qId = do
  ((result, _), _) <- runFormPost createQuestionForm
  mAuth <- maybeAuth
  case mAuth of
    Just auth -> do
      mQuiz <- runDB $ get qId
      case mQuiz of
        Just quiz ->
          if (quizUserId quiz) == entityKey auth
            then do
              createQuestion result qId
              redirect (QuizR qId)
            else redirect (QuizR qId)
        Nothing -> redirect HomeR
    Nothing -> redirect HomeR

getAvailableQuizzes :: Key User -> HandlerT App IO [Entity Quiz]
getAvailableQuizzes uId = runDB $ do
  shared <- selectList [SharedQuizUserId ==. uId] []
  let publicOrOwnFilter = [QuizPublicAccess ==. True] ||. [QuizUserId ==. uId]
  let sharedQuizIds = map (sharedQuizQuizId . entityVal) shared
  let quizFilter = foldr (||.) publicOrOwnFilter $ map (\id -> [QuizId ==. id]) sharedQuizIds
  quizzes <- selectList quizFilter []
  return quizzes

getAnswers :: Key Question -> HandlerT App IO [Entity Answer]
getAnswers qId = runDB $ do
  answers <- selectList [AnswerQuestionId ==. qId] []
  return answers

getAllAnswers :: [Entity Question] -> HandlerT App IO [(Entity Question, [Entity Answer])]
getAllAnswers (q:questions) = do
  answers <- getAnswers $ entityKey q
  rest <- getAllAnswers questions
  return $ (q, answers):rest
getAllAnswers [] = return []

getQuestions :: Key Quiz -> HandlerT App IO [(Entity Question, [Entity Answer])]
getQuestions qId = do
  questions <- runDB $ selectList [QuestionQuizId ==. qId] []
  allAnswers <- getAllAnswers questions
  return allAnswers

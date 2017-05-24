module Handler.Quiz where

import Import
import Yesod.Form.Jquery
import Data.Aeson.Types (Result(..))

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

createAnswers :: [(Text, Bool)] -> Key Question -> Handler ()
createAnswers ((answer, correct):answers) qId = do
  _ <- runDB $ insert (Answer qId answer correct)
  createAnswers answers qId
createAnswers [] _ = return ()

createQuestion :: Question -> [(Text, Bool)] -> Key Quiz -> Handler ()
createQuestion question answers qId = do
  questionId <- runDB $ insert $ question {questionQuizId = qId}
  _ <- createAnswers answers questionId
  return ()

createQuestionF :: FormResult FormQuestion -> Key Quiz -> HandlerT App IO ()
createQuestionF formResult qId =
  case formResult of
    FormSuccess (FormQuestion question a1 c1 a2 c2 a3 c3 a4 c4) -> createQuestion (Question qId question) [(a1, c1), (a2, c2), (a3, c3), (a4, c4)] qId
    _ -> return ()

createQuizForm :: Html -> MForm Handler (FormResult FormQuiz, Widget)
createQuizForm = renderDivs $ FormQuiz
  <$> areq textField "Title" Nothing
  <*> areq textField "Topic" Nothing
  <*> areq checkBoxField "Public" Nothing

createQuizF :: FormResult FormQuiz -> Key User -> HandlerT App IO ()
createQuizF formResult userId =
  case formResult of
    FormSuccess (FormQuiz title topic public) -> createQuiz (Quiz title userId topic public) userId
    _ -> return ()

createQuiz :: Quiz -> Key User -> Handler ()
createQuiz quiz userId = do
  _ <- runDB $ insert $ quiz {quizUserId = userId}
  return ()

getQuizzesR :: Handler TypedContent
getQuizzesR = do
  mAuth <- maybeAuth
  (quizForm, enctype) <- generateFormPost createQuizForm
  case mAuth of
    Nothing -> do
      quizzes <- getPublicQuizzes
      selectRep $ do
        provideJson quizzes
        provideRep $ defaultLayout $ do
          setTitle "Quizzes"
          $(widgetFile "quizlist")
    Just auth -> do
      quizzes <- getAvailableQuizzes $ entityKey auth
      selectRep $ do
        provideJson quizzes
        provideRep $ defaultLayout $ do
          setTitle "Quizzes"
          $(widgetFile "quizlist")

postMkQuizR :: Handler Html
postMkQuizR = do
  mAuth <- maybeAuth
  case mAuth of
    Just auth -> do
      ((result, _), _) <- runFormPost createQuizForm
      jsonQuiz <- parseJsonBody
      case jsonQuiz of
        Success quiz -> do
          createQuiz quiz $ entityKey auth
          redirect QuizzesR
        Error _ -> do
          createQuizF result (entityKey auth)
          redirect QuizzesR
    Nothing -> redirect HomeR

data QuizInfo = QuizInfo (Maybe Quiz) Bool

instance ToJSON QuizInfo where
  toJSON (QuizInfo q o) = object
    [
      "maybequiz" .= q
      , "owner" .= o
    ]

getQuizR :: Key Quiz -> Handler TypedContent
getQuizR qId = do
  (questionForm, enctype) <- generateFormPost createQuestionForm
  questions <- getQuestions qId
  mAuth <- maybeAuth
  quiz <- runDB $ get qId
  let ownsQuiz = case (quiz >>= (\q -> mAuth >>= (\m -> return (entityKey m == quizUserId q)))) of
        Nothing -> False
        Just x -> x
  let quizAccess = ownsQuiz ||
        case quiz of
          Nothing -> False
          Just q -> quizPublicAccess q
  selectRep $ do
    provideJson $ case quizAccess of
      True -> QuizInfo quiz ownsQuiz
      False -> QuizInfo Nothing False
    provideRep $ defaultLayout $ do
      setTitle "Quiz"
      $(widgetFile "quiz")

postQuestionR :: Key Quiz -> Handler Html
postQuestionR qId = do
  mAuth <- maybeAuth
  case mAuth of
    Just auth -> do
      mQuiz <- runDB $ get qId
      case mQuiz of
        Just quiz ->
          if (quizUserId quiz) == entityKey auth -- Verify that the person sending the request owns the quiz
            then do
              ((result, _), _) <- runFormPost createQuestionForm
              jsonQuestion <- parseJsonBody
              case jsonQuestion of
                Success (question, answers) -> do
                  createQuestion question answers qId
                  redirect (QuizR qId)
                Error _ -> do
                  createQuestionF result qId
                  redirect (QuizR qId)
            else redirect (QuizR qId)
        Nothing -> redirect HomeR
    Nothing -> redirect HomeR

getAvailableQuizzes :: Key User -> HandlerT App IO [Entity Quiz]
getAvailableQuizzes uId = runDB $ do
  shared <- selectList [SharedQuizUserId ==. uId] []
  let publicOrOwnFilter = [QuizPublicAccess ==. True] ||. [QuizUserId ==. uId]
  let sharedQuizIds = map (sharedQuizQuizId . entityVal) shared
  let quizFilter = foldr (||.) publicOrOwnFilter $ map (\id -> [QuizId ==. id]) sharedQuizIds -- All quizzes which are either public, owned by the user, or shared with the user
  quizzes <- selectList quizFilter []
  return quizzes

getPublicQuizzes :: Handler [Entity Quiz]
getPublicQuizzes = runDB $ selectList [QuizPublicAccess ==. True] []

getAnswers :: Key Question -> HandlerT App IO [Entity Answer]
getAnswers qId = runDB $ do
  answers <- selectList [AnswerQuestionId ==. qId] []
  return answers

getAllAnswers :: [Entity Question] -> HandlerT App IO [(Entity Question, [Entity Answer])]
-- Loop to recursively get answers, paird with the appropriate questions, for a given quiz
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

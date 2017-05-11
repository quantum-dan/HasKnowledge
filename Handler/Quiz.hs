module Handler.Quiz where

import Import

data FormQuiz = FormQuiz {
  fqTitle :: Text,
  fqTopic :: Text,
  fqPublic :: Bool
                         }
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

postQuizR :: Handler Html
postQuizR = do
  ((result, _), _) <- runFormPost createQuizForm
  mAuth <- maybeAuth
  case mAuth of
    Just auth -> do
      createQuiz result (entityKey auth)
      redirect QuizzesR
    Nothing -> redirect HomeR

getAvailableQuizzes :: Key User -> HandlerT App IO [Entity Quiz]
getAvailableQuizzes uId = runDB $ do
  shared <- selectList [SharedQuizUserId ==. uId] []
  let publicOrOwnFilter = [QuizPublicAccess ==. True] ||. [QuizUserId ==. uId]
  let sharedQuizIds = map (sharedQuizQuizId . entityVal) shared
  let quizFilter = foldr (||.) publicOrOwnFilter $ map (\id -> [QuizId ==. id]) sharedQuizIds
  quizzes <- selectList quizFilter []
  return quizzes

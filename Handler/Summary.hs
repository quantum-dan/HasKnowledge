module Handler.Summary where

import Import

data FormSummary = FormSummary {
  fsTitle :: Text,
  fsTopic :: Text,
  fsContent :: Textarea,
  fsPublic :: Bool
                               }

createSummaryForm :: Html -> MForm Handler (FormResult FormSummary, Widget)
createSummaryForm = renderDivs $ FormSummary
  <$> areq textField "Title" Nothing
  <*> areq textField "Topic" Nothing
  <*> areq textareaField "Summary" Nothing
  <*> areq checkBoxField "Public?" Nothing

getSummariesR :: Handler Html
getSummariesR = do
  (summaryForm, enctype) <- generateFormPost createSummaryForm
  mAuth <- maybeAuth
  summaries <- case mAuth of
    Just auth -> getSummaries $ entityKey auth
    Nothing -> getPublicSummaries
  defaultLayout $ do
    setTitle "Summaries"
    $(widgetFile "summarylist")

postSummariesR :: Handler Html
postSummariesR = do
  ((result, _), _) <- runFormPost createSummaryForm
  mAuth <- maybeAuth
  case mAuth of
    Nothing -> redirect HomeR
    Just auth -> case result of
      FormSuccess fs -> do
        _ <- addSummary auth fs
        redirect SummariesR
      _ -> redirect SummariesR

getSummaryR :: Key Summary -> Handler Html
getSummaryR sId = do
  mAuth <- maybeAuth
  mSummary <- getSummary sId mAuth
  case mSummary of
    Nothing -> redirect SummariesR
    Just summary -> defaultLayout $ do
      setTitle $ toHtml $ summaryTitle summary
      $(widgetFile "summary")

getSummary :: Key Summary -> Maybe (Entity User) -> HandlerT App IO (Maybe Summary)
  -- Also verifies that the user has access to the summary in question
getSummary sId mAuth = do
  mSummary <- runDB $ get sId
  return $ mSummary >>= (\summary -> do
                            if (summaryPublicAccess summary) then Just summary
                              else mAuth >>= (\auth ->
                                                if (entityKey auth) == (summaryUserId summary) then Just summary else Nothing)
                        )

addSummary :: Entity User -> FormSummary -> HandlerT App IO ()
addSummary auth (FormSummary title topic content public) = do
  let uId = entityKey auth
  _ <- runDB $ insert $ Summary title topic uId (unTextarea content) public
  return ()

getSummaries :: Key User -> HandlerT App IO [Entity Summary]
getSummaries uId = runDB $ selectList ([SummaryUserId ==. uId] ||. [SummaryPublicAccess ==. True]) []

getPublicSummaries :: HandlerT App IO [Entity Summary]
getPublicSummaries = runDB $ selectList [SummaryPublicAccess ==. True] []

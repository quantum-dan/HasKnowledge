module Handler.Summary where

import Import
import Data.Aeson.Types (Result (..))
import Data.List (nub)

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

getSummariesR :: Handler TypedContent
getSummariesR = do
  (summaryForm, enctype) <- generateFormPost createSummaryForm
  mAuth <- maybeAuth
  summaries <- case mAuth of
    Just auth -> getSummaries $ entityKey auth
    Nothing -> getPublicSummaries
  selectRep $ do
    provideJson summaries
    provideRep $ defaultLayout $ do
      setTitle "Summaries"
      $(widgetFile "summarylist")

postSummariesR :: Handler TypedContent
postSummariesR = do
  auth <- requireAuth
  ((result, _), _) <- runFormPost createSummaryForm
  mSummary <- parseJsonBody
  case mSummary of
    Success summary -> do
      _ <- addSummary auth summary
      redirect SummariesR
    Error _ ->
      case result of
        FormSuccess fs -> do
          _ <- addSummaryForm auth fs
          redirect SummariesR
        _ -> redirect SummariesR

getSummaryR :: Key Summary -> Handler TypedContent
getSummaryR sId = do
  mAuth <- maybeAuth
  mSummary <- getSummary sId mAuth
  case mSummary of
    Nothing -> redirect SummariesR
    Just summary -> selectRep $ do
      provideJson summary
      provideRep $ defaultLayout $ do
        setTitle $ toHtml $ summaryTitle summary
        $(widgetFile "summary")

deleteSummaryR :: Key Summary -> Handler TypedContent
deleteSummaryR summaryId = do
  auth <- requireAuth
  mSummary <- runDB $ get summaryId
  case mSummary of
    Nothing -> redirect SummariesR
    Just summary -> if summaryUserId summary == entityKey auth
      then (runDB $ delete summaryId) >> redirect SummariesR
      else selectRep $ do
        provideJson $ object ["error" .= ("You do not own this summary" :: Text)]
        provideRep $ return [shamlet|<p>You do not own this summary.|]

getFilteredSummariesR :: Text -> Handler TypedContent
getFilteredSummariesR topic = do
  mAuth <- maybeAuth
  summaries <- case mAuth of
    Just auth -> filterByTopic (entityKey auth) topic
    Nothing -> filterByTopicNoUser topic
  selectRep $ do
    provideJson summaries
    provideRep $ do
      (summaryForm, enctype) <- generateFormPost createSummaryForm
      defaultLayout $ do
        setTitle $ toHtml $ "Summaries with Topic: " ++ topic
        $(widgetFile "summarylist")

getSummary :: Key Summary -> Maybe (Entity User) -> HandlerT App IO (Maybe Summary)
  -- Also verifies that the user has access to the summary in question
getSummary sId mAuth = do
  mSummary <- runDB $ get sId
  return $ mSummary >>= (\summary -> do
                            if (summaryPublicAccess summary) then Just summary
                              else mAuth >>= (\auth ->
                                                if (entityKey auth) == (summaryUserId summary) then Just summary else Nothing)
                        )

addSummaryForm :: Entity User -> FormSummary -> HandlerT App IO ()
addSummaryForm auth (FormSummary title topic content public) = do
  addSummary auth $ Summary title topic (entityKey auth) (unTextarea content) public

addSummary :: Entity User -> Summary -> Handler ()
addSummary auth summary = do
  let uId = entityKey auth
  _ <- runDB $ insert $ summary {summaryUserId = uId}
  return ()

getSummaries :: Key User -> HandlerT App IO [Entity Summary]
getSummaries uId = runDB $ selectList ([SummaryUserId ==. uId] ||. [SummaryPublicAccess ==. True]) []

getPublicSummaries :: HandlerT App IO [Entity Summary]
getPublicSummaries = runDB $ selectList [SummaryPublicAccess ==. True] []

filterByTopic :: Key User -> Text -> Handler [Entity Summary]
filterByTopic userId topic = runDB $ selectList (([SummaryPublicAccess ==. True] ||. [SummaryUserId ==. userId]) ++ [SummaryTopic ==. topic]) []

filterByTopicNoUser :: Text -> Handler [Entity Summary]
filterByTopicNoUser topic = runDB $ selectList [SummaryPublicAccess ==. True, SummaryTopic ==. topic] []

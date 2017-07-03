module Handler.Home where

import Import
import Yesod.Form.Bootstrap3 (BootstrapFormLayout (..), renderBootstrap3)
import Text.Julius (RawJS (..))
import Handler.Account (usernameForm)

-- Define our data that will be used for creating the form.
data FileForm = FileForm
    { fileInfo :: FileInfo
    , fileDescription :: Text
    }

-- This is a handler function for the GET request method on the HomeR
-- resource pattern. All of your resource patterns are defined in
-- config/routes
--
-- The majority of the code you will write in Yesod lives in these handler
-- functions. You can spread them across multiple files if you are so
-- inclined, or create a single monolithic file.
getHomeR :: Handler Html
getHomeR = do
        mAuth <- maybeAuth
        let loginUrl = "/auth/page/googleemail2/forward" :: Text -- Google+ login link, instead of a dedicated login page
        defaultLayout $ do
          aDomId <- newIdent
          setTitle "HasKnowledge"
          $(widgetFile "homepage")

getHomeTestR :: Handler Html -- For JavaScript testing
getHomeTestR = do
  defaultLayout $ do
    setTitle "HasKnowledge"
    $(widgetFile "hptest")


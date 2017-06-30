{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

module JSONClass (JSON, toJValue, fromJValue)
  where

type JSONError = String

class JSON a where
  toJValue :: a -> JValue
  fromJValue :: JValue -> Either JSONError a

instance JSON JValue where 
  toJValue = id 
  fromJValue = Right


data JValue = JString String |
              JInt Int |
              JNumber Double |
              JBool Bool |
              JNull |
              JObject (JObj JValue) |
              JArray (JAry JValue)
              deriving (Eq, Ord, Show)

instance JSON Bool where
  toJValue = JBool
  fromJValue (JBool b) = Right b
  fromJValue _ = Left "Not a JSon boolean"

instance JSON String where
  toJValue               = JString
  fromJValue (JString s) = Right s
  fromJValue _           = Left "Not a JSon string"


doubleToJValue :: (Double -> a) -> JValue -> Either JSONError a
doubleToJValue f (JNumber v) = Right (f v)
doubleToJValue _ _           = Left "not a JSON number"

instance JSON Int where
  toJValue = JNumber . realToFrac
  fromJValue = doubleToJValue round

instance JSON Integer where 
  toJValue = JNumber . realToFrac
  fromJValue = doubleToJValue round

instance JSON Double where
  toJValue = JNumber
  fromJValue = doubleToJValue id

newtype JAry a = JAry {
    fromJAry :: [a]
  } deriving (Eq, Ord, Show)

jary :: [a] -> JAry a
jary = JAry

newtype JObj a = JObj {
    fromJObj :: [(String, a)]
  } deriving (Eq, Ord, Show)


jaryFromJValue :: (JSON a) => JValue -> Either JSONError (JAry a)
jaryFromJValue (JArray (JAry a)) =
  whenRight JAry (mapEithers fromJValue a)
jaryFromJValue _ = Left "not a JSON array"

jaryToJValue :: (JSON a) => JAry a -> JValue
jaryToJValue = JArray . JAry . map toJValue . fromJAry

instance (JSON a) => JSON (JAry a) where
  toJValue = jaryToJValue
  fromJValue = jaryFromJValue

listToJValues :: (JSON a) => [a] -> [JValue]
listToJValues = map toJValue

jvaluesToJAry :: [JValue] -> JAry JValue
jvaluesToJAry = JAry

jaryOfValuesToJValue :: JAry JValue -> JValue
jaryOfValuesToJValue = JArray


whenRight :: (b -> c) -> Either a b -> Either a c
whenRight _ (Left err) = Left err
whenRight f (Right a) = Right (f a)

mapEithers :: (a -> Either b c) -> [a] -> Either b [c]
mapEithers f (x:xs) = case mapEithers f xs of
                        Left err -> Left err
                        Right ys -> case f x of 
                                      Left err -> Left err
                                      Right y -> Right (y:ys)
mapEithers _ _ = Right []

module Main where

import SimpleJSON
import PutJSON

main = print (renderJValue (JObject [("foo", JNumber 1), ("bar", JBool False)]))

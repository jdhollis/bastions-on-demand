(ns trigger-bastion-destruction.handler
  (:require [clojure.string :as cs]
            [cljs.nodejs :as node]))

(node/enable-util-print!)

(def AWS
  (node/require "aws-sdk"))

(def lambda
  (new AWS.Lambda))

(defn env
  [k]
  (aget js/process.env k))

(def destroy-bastion-function-name (env "DESTROY_BASTION_FUNCTION_NAME"))

(defn ^:export handle-request
  [event _ callback]
  (let [event (js->clj event :keywordize-keys true)
        user (last (cs/split (get-in event [:requestContext :identity :userArn]) #"/"))
        payload (.stringify js/JSON (clj->js {:user user}))]
    (.invoke lambda
             (clj->js {:FunctionName   destroy-bastion-function-name
                       :InvocationType "Event"
                       :Payload        payload})
             (fn [_ _]
               (callback nil (clj->js {:statusCode 200}))))))

(ns bastion.destroy
  (:gen-class
    :implements [com.amazonaws.services.lambda.runtime.RequestStreamHandler])
  (:require [clojure.java.io :as io]
            [cheshire.core :as json]
            [bastion.sg :as sg]
            [bastion.task :as task]))

(defn -handleRequest
  [_ input-stream _ _]
  (let [event (json/parse-stream (io/reader input-stream) true)
        user (:user event)]
    (if-let [task (task/get-for user)]
      (task/stop-for user task))
    (sg/delete-for user)))

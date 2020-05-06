(ns bastion.create
  (:gen-class
    :implements [com.amazonaws.services.lambda.runtime.RequestStreamHandler])
  (:require [clojure.java.io :as io]
            [clojure.string :as cs]
            [cheshire.core :as json]
            [bastion.sg :as sg]
            [bastion.task :as task]))

(def ^:private base-response
  {:body       {:ip nil}
   :statusCode 201})

(defn- stream-response
  [bastion-ip output-stream]
  (let [response (assoc-in base-response [:body :ip] bastion-ip)]
    (with-open [writer (io/writer output-stream)]
      (json/generate-stream (assoc response :body (json/generate-string (:body response))) writer))))

(defn- start-bastion-and-stream-response
  [user cidr-ip output-stream & [security-group-id]]
  (let [task (if security-group-id
               (task/run-for user security-group-id)
               (->> (sg/create-for user cidr-ip)
                    (task/run-for user)))]
    (stream-response (:bastion-ip task) output-stream)))

(defn -handleRequest
  [_ input-stream output-stream _]
  (let [event (json/parse-stream (io/reader input-stream) true)
        cidr-ip (str (get-in event [:requestContext :identity :sourceIp]) "/32")
        user (last (cs/split (get-in event [:requestContext :identity :userArn]) #"/"))]
    (if-let [security-group-id (sg/get-id-for user)]
      (if (sg/ip-matches? security-group-id cidr-ip)
        (if-let [task (task/get-for user)]
          (stream-response (:bastion-ip task) output-stream)
          (start-bastion-and-stream-response user cidr-ip output-stream security-group-id))
        (if-let [task (task/get-for user)]
          (do
            (task/stop-for user task)
            (sg/delete-for user)
            (start-bastion-and-stream-response user cidr-ip output-stream))
          (do
            (sg/delete-for user)
            (start-bastion-and-stream-response user cidr-ip output-stream))))
      (start-bastion-and-stream-response user cidr-ip output-stream))))

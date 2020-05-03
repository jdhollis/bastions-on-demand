(defproject bastion "0.1.0-SNAPSHOT"
  :description "bastion"
  :dependencies [[org.clojure/clojure "1.10.1"]
                 [org.clojure/core.async "1.1.587"]
                 [com.cognitect.aws/api "0.8.456"]
                 [com.cognitect.aws/endpoints "1.1.11.774"]
                 [com.cognitect.aws/ec2 "796.2.657.0"]
                 [com.cognitect.aws/ecs "796.2.656.0"]
                 [com.amazonaws/aws-lambda-java-core "1.2.1"]
                 [cheshire "5.10.0"]
                 [digest "1.4.9"]]
  :jvm-opts ["-Dclojure.compiler.elide-meta=[:doc]"
             "-Dclojure.compiler.direct-linking=true"]
  :profiles {:uberjar {:aot         :all
                       :global-vars {*warn-on-reflection* true}}
             :create  {:main         bastion.create
                       :name         "create-bastion"
                       :uberjar-name "create-bastion.jar"}
             :destroy {:main         bastion.destroy
                       :name         "destroy-bastion"
                       :uberjar-name "destroy-bastion.jar"}})

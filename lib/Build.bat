ildasm RdKafka.dll /out:RdKafka.il
ren RdKafka.dll RdKafka.dll.dll.orig
ilasm RdKafka.il /dll /key=kafkakey.snk 
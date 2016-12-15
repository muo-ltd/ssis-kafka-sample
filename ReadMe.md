# SSIS Kafka Sample



This project shows how you can connect SSIS (SQL Server Integration Services) to Kafka. SSIS requires referenced components
to be in the GAC (Global Assembly Cache) so libraries used need to be signed with a strong key.

## rdkafka-dotnet

There is a C# Client for Kafka called [rdkafka-dotnet](https://github.com/ah-/rdkafka-dotnet), it is based upon the commonly used 
[librdkafka](https://github.com/edenhill/librdkafka) C library which is used in a large number of clients. The simplest way to 
obtain it is to add it via nuget. 

## Generate and Install a GAC friendly version

However in SSIS referenced assemblies must be in the GAC, and in order to be added to the 
GAC they must be strongly named. To convert the rdkafka assembly you can do the following:
- Create a console app and add a Nuget reference to rdkafka. Build the application
- Copy the RdKafka.dll and the x64 and x86 directories from the bin/debug (or release) to a different location
- Use a console that has access to the `sn` command and run the following:
    - `sn -k kafkakey.snk`
- Use a console that has access to the `ildasm` command and run the following:
    - `ildasm RdKafka.dll /out:RdKafka.il` 
    - `ren RdKafka.dll RdKafka.dll.dll.orig`
    - `ilasm RdKafka.il /dll /key=kafkakey.snk`

The RdKafka.dll is now strongly named. You now need to install it into the GAC. To do this you need to execute the command:
`gacutil -i RdKafka.dll`
However although this copies it into the Gac it still will not work as the required `librdkafka.dll` are not copied as well. 
You need to find the location of the `RdKafka.dll` in your GAC. This will be somewhere like 
`c:\windows\Microsoft.net\GAC_MSIL\rdkafka\v4****`
Copy the x64 and x86 directories into the same directory as the Rdkafka.dll and it is ready to run. 

The lib directory of this code base contains a Build.bat script that performs the generation steps of the process, and an 
Install.bat file that installs the RdKafka.dll into the Gac. You must still manually copy the x64 and x86 folders though. 

## How to use in SSIS

Within SSIS you can add a Script task. When you edit that task you should add a reference to the strongly named version of RdKakfa, 
if you are using the version in this sample then add a reference to the copy in the lib directory which has already been processed. 
You can then simple use standard RdKafka style code to Publish or Subscribe to messages. 

```
                var config = new Config() { GroupId = "ssiskafka" };
                using (var consumer = new EventConsumer(config, "<kafka address>:9092"))
                {
                    consumer.OnMessage += (obj, msg) =>
                    {
                        string text = Encoding.UTF8.GetString(msg.Payload, 0, msg.Payload.Length);
                        Dts.Log($"Topic: {msg.Topic} Partition: {msg.Partition} Offset: {msg.Offset} {text}", 0, new byte[0]);
                    };

                    consumer.Subscribe(new List<string>() { "<kafka topic to subscribe to>" });
                    consumer.Start();

                    Dts.Log("Consumer Started", 0, new byte[0]);

                    //Exit after 30 seconds
                    System.Threading.Thread.Sleep(30000);
                }

```

## Kafka 

You can use docker to run an instance of Kafka locally. For example [wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker)
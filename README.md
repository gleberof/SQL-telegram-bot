# SQL telegram bot. 

# The purpose.
To send and receive messages to/from telegram bot with MS SQL server (by stored procedures)

# Prerequsites
* SQL Server 2016 or higher
* Registered telegram bot [check here](https://docs.microsoft.com/en-us/azure/bot-service/bot-service-channel-connect-telegram?view=azure-bot-service-4.0) via [Bot Father](https://telegram.me/botfather)


# How to install
1. Clone repo ```git clone ```
2. Run setup.sql (new db \[NAME\] with all nessesaey prcedures will be created)
3. Set bot_token given by [Bot Father](https://telegram.me/botfather) How?


# How to use
1. Know you telegram ID 
    * Send a message via telegram to your bot
    * Run [].[get_last_id] - to get your ID (please remeber it somewhere)
2. Send a message from SQL by [].[send_message] [yourID] (int), N'My message to bot'

# TODO
1. Listen cycle 
2. Progress bar
3. Execute queries and return results
4. Send pictures
5. Merge with monitoring

# PowerShell-CosmosDB-Data-Pipeline

Automate data collection and storage for your Azure Cosmos DB with this PowerShell data pipeline.

This repository provides two PowerShell scripts that streamline data collection and storage for monitoring and analysis in your Azure Cosmos DB.

## Scripts

* #### ExtractMetrics.ps1: 
     This script collects system metrics like CPU, memory, and disk usage. You can easily modify this 
     script to collect data from other sources.
* #### SendDataToCosmosDB.ps1: 
     This script creates Cosmos DB documents from the collected metrics and inserts them into your database

  ![image](https://github.com/user-attachments/assets/be16303a-7d1b-4963-8f44-c10adb4c2c2c)

## Usage
* #### Internet of Things (IoT) Data Management: 
     Collect and store data from IoT devices in Cosmos DB using this pipeline. Leverage the scalability and 
     flexibility of Cosmos DB to manage large volumes of sensor data efficiently.
* #### Automated Monitoring: 
     Collect and store system metrics (CPU, memory, disk usage) over time for proactive monitoring and performance 
     analysis. Identify potential bottlenecks or resource constraints before they impact system performance. You can 
     modify ExtractMetrics.ps1 to collect data from various sources beyond system metrics

* #### Improved Model Performance: 
     By ensuring a consistent flow of fresh data, the pipeline helps your AI models stay up-to-date and 
     potentially improve their accuracy and performance over time.


## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change. If you want to add an feature. I'm open to that also !! 

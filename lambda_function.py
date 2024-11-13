import json
import pandas as pd
import talib

def lambda_handler(event, context):
    # Sample data
    data = {
        'date': ['2022-01-01', '2022-01-02', '2022-01-03', '2022-01-04', '2022-01-05',
                 '2022-01-06', '2022-01-07', '2022-01-08', '2022-01-09', '2022-01-10'],
        'close': [150.0, 152.0, 153.0, 154.5, 156.0, 157.5, 159.0, 160.5, 162.0, 163.5]
    }

    # Convert the data into a DataFrame
    df = pd.DataFrame(data)
    df['date'] = pd.to_datetime(df['date'])  # Ensure 'date' is in datetime format

    # Calculate the 5-period Simple Moving Average (SMA) using TA-Lib
    df['SMA_5'] = talib.SMA(df['close'], timeperiod=5)

    # Convert the result to JSON
    result = df.to_json(orient="records", date_format="iso")

    return {
        'statusCode': 200,
        'body': json.loads(result)
    }
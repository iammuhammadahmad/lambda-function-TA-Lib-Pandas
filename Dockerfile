# Use the official AWS Lambda Python runtime image
FROM public.ecr.aws/lambda/python:3.10

# Set the working directory in the container
WORKDIR ${LAMBDA_TASK_ROOT}

# Install OS dependencies
RUN yum install -y tar make gzip gcc

#Note:
#If the line 15 command fails, you can manually download the ta-lib-0.4.0-src.tar.gz file from https://sourceforge.net/projects/ta-lib/files/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz/download.
#In my location, automatic download was restricted, so I downloaded it manually. I have verified that automatic download works in the AWS US East region. If you are in a compatible region, uncomment line 15 and comment out line 18 to test automatic download. 

# Download TA-Lib
# RUN wget -O ta-lib-0.4.0-src.tar.gz https://sourceforge.net/projects/ta-lib/files/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz

# Copy files to docker
COPY ta-lib-0.4.0-src.tar.gz .
COPY requirements.txt .
COPY lambda_function.py .

# Install the TA-Lib
RUN tar -xvzf ta-lib-0.4.0-src.tar.gz \
    && cd ta-lib/ \
    && ./configure --prefix=/usr \
    && make install

# Install Python dependencies
RUN pip install -r requirements.txt

# Specify the command that runs your Lambda function
CMD ["lambda_function.lambda_handler"]

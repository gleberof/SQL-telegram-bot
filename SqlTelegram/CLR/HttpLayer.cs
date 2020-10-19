using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;

namespace SqlTelegram
{
    internal class HttpLayer
    {
        private const string telegram_url = "https://api.telegram.org/bot";

        public static HttpResult Get(
          string url,
          IEnumerable<KeyValuePair<string, string>> headers)
        {
            HttpResult httpResult = new HttpResult();
            if (string.IsNullOrEmpty(url))
            {
                httpResult.Error = httpResult.ErrorMessage = "Invalid URL";
                return httpResult;
            }
            try
            {
                url = String.Concat(telegram_url, url);
                ServicePointManager.Expect100Continue = true;
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Ssl3 | SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "GET";
                HttpLayer.AddHeaders(req, headers);
                HttpWebResponse response = (HttpWebResponse)req.GetResponse();
                using (StreamReader streamReader = new StreamReader(response.GetResponseStream()))
                    httpResult.Response = streamReader.ReadToEnd();
                httpResult.Success = response.StatusCode == HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Accepted;
            }
            catch (Exception ex)
            {
                httpResult.ErrorMessage = ex.Message;
                httpResult.Error = ex.ToString();
            }
            return httpResult;
        }

        public static HttpResult Post(
          string url,
          IEnumerable<KeyValuePair<string, string>> headers,
          string requestBody)
        {
            HttpResult httpResult = new HttpResult();
            if (string.IsNullOrEmpty(url))
            {
                httpResult.Error = httpResult.ErrorMessage = "Invalid URL";
                return httpResult;
            }
            try
            {
                url = String.Concat(telegram_url, url);
                ServicePointManager.Expect100Continue = true;
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Ssl3 | SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
                req.Method = "POST";
                HttpLayer.AddHeaders(req, headers);
                if (!string.IsNullOrEmpty(requestBody))
                {
                    byte[] bytes = Encoding.UTF8.GetBytes(requestBody);
                    req.ContentLength = bytes.Length;
                    using (Stream streamWriter = req.GetRequestStream())
                    {
                        streamWriter.Write(bytes, 0, bytes.Length);
                        streamWriter.Flush();
                        streamWriter.Close();
                    }
                }
                else
                    req.ContentLength = 0L;
                HttpWebResponse response = (HttpWebResponse)req.GetResponse();
                using (StreamReader streamReader = new StreamReader(response.GetResponseStream()))
                    httpResult.Response = streamReader.ReadToEnd();
                httpResult.Success = response.StatusCode == HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Accepted;
            }
            catch (Exception ex)
            {
                httpResult.ErrorMessage = ex.Message;
                httpResult.Error = ex.ToString();
            }
            return httpResult;
        }

        private static void AddHeaders(
          HttpWebRequest req,
          IEnumerable<KeyValuePair<string, string>> headers)
        {
            if (headers == null)
                return;
            foreach (KeyValuePair<string, string> header in headers)
            {
                string key = header.Key;
                string s = header.Value;
                if (WebHeaderCollection.IsRestricted(key))
                {
                    switch (header.Key)
                    {
                        case "Accept":
                            req.Accept = s;
                            continue;
                        case "Connection":
                            req.Connection = s;
                            continue;
                        case "Content-Length":
                            req.ContentLength = long.Parse(s);
                            continue;
                        case "Content-Type":
                            req.ContentType = s;
                            continue;
                        case "Date":
                            req.Date = DateTime.Parse(s);
                            continue;
                        case "Expect":
                            req.Expect = s;
                            continue;
                        case "Host":
                            req.Host = s;
                            continue;
                        case "If-Modified-Since":
                            req.IfModifiedSince = DateTime.Parse(s);
                            continue;
                        case "Referer":
                            req.Referer = s;
                            continue;
                        case "Transfer-Encoding":
                            req.TransferEncoding = s;
                            continue;
                        case "User-Agent":
                            req.UserAgent = s;
                            continue;
                        case "Range":
                            throw new ApplicationException("Range header is not supported.");
                        case "Proxy-Connection":
                            throw new ApplicationException("Proxy-Connection header is not supported.");
                        default:
                            continue;
                    }
                }
                else
                    req.Headers.Add(key, s);
            }
        }
    }
}

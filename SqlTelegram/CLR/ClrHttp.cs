using Microsoft.SqlServer.Server;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Collections.Generic;
using System.Xml;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Security;

namespace SqlTelegram
{
    public class ClrHttp
    {
        [SqlProcedure]
        public static void HttpGet(
          SqlString url,
          SqlXml headerXml,
          out SqlBoolean success,
          out SqlString response,
          out SqlString error)
        {
            List<KeyValuePair<string, string>> headers = ClrHttp.GetHeaders(headerXml);
            HttpResult httpResult = HttpLayer.Get(url.IsNull ? (string)null : url.Value, (IEnumerable<KeyValuePair<string, string>>)headers);
            success = (SqlBoolean)httpResult.Success;
            response = (SqlString)httpResult.Response;
            error = (SqlString)httpResult.Error;
        }

        [SqlProcedure]
        public static void HttpPost(
          SqlString url,
          SqlXml headerXml,
          SqlString requestBody,
          out SqlBoolean success,
          out SqlString response,
          out SqlString error)
        {
            List<KeyValuePair<string, string>> headers = ClrHttp.GetHeaders(headerXml);
            string url1 = url.IsNull ? (string)null : url.Value;
            string requestBody1 = requestBody.IsNull ? (string)null : requestBody.Value;
            HttpResult httpResult = HttpLayer.Post(url1, (IEnumerable<KeyValuePair<string, string>>)headers, requestBody1);
            success = (SqlBoolean)httpResult.Success;
            response = (SqlString)httpResult.Response;
            error = (SqlString)httpResult.Error;
        }

        [SqlProcedure]
        public static void Message2Command(
        SqlString json,
        SqlString bot_name,
        SqlString chat_id,
        out SqlString response)
        {

            string result = "";
            response = (SqlString)"";
            Dictionary<string, object> obj = JObject.FromObject(JsonConvert.DeserializeObject(json.ToString())).ToObject<Dictionary<string, object>>();

            JArray replies = (JArray)obj["result"];

            foreach (JToken reply in replies)
            {

                Dictionary<string, object> dreply = JObject.FromObject(reply).ToObject<Dictionary<string, object>>();

                if (dreply.ContainsKey("message"))
                {
                    Dictionary<string, object> message = JObject.FromObject(dreply["message"]).ToObject<Dictionary<string, object>>();
                    Dictionary<string, object> chat = JObject.FromObject(message["chat"]).ToObject<Dictionary<string, object>>();
                    if (message.ContainsKey("entities") & chat["id"].ToString()==chat_id.ToString())
                    {
                        string text = message["text"].ToString();
                        JArray entities = (JArray)message["entities"];
                        foreach (JToken elm in entities)
                        {
                            if (elm["type"].ToString() == "bot_command")
                            {
                                string command = text.Substring((int)elm["offset"], (int)elm["length"]);
                                if (command.Split('@')[1] == bot_name.ToString())
                                {
                                    result = command.Split('@')[0].Substring(1);
                                    break;
                                }

                            }

                        }
                    }

                }
            }
            if (result != "")
            {
                SqlString txt_query = "";
                SqlString columns_width = "";

                try
                {
                    using (SqlConnection connection = new SqlConnection("context connection=true"))
                    {
                        connection.Open();
                        //SqlCommand sqlCommand = new SqlCommand("SELECT [query] FROM [dbo].[commands] WHERE [command] = @command", connection);
                        //sqlCommand.Parameters.AddWithValue("@command", result);
                        //txt_query = (SqlString)(string)sqlCommand.ExecuteScalar();

                        SqlCommand sqlCommand = new SqlCommand("SELECT [query], [columns_width] FROM [dbo].[commands] WHERE [command] = @command", connection);
                        sqlCommand.Parameters.AddWithValue("@command", result);
                        SqlDataReader reader = sqlCommand.ExecuteReader();
                        while (reader.Read())
                        {
                            txt_query = reader["query"].ToString();
                            columns_width = reader["columns_width"].ToString();
                        }
                        reader.Close();
                    }
                    if (txt_query != "")
                    {
                        SQL2string(txt_query, 10, 6, 10, columns_width, out response);
                    }
                }
                catch { }
            }
        }

        [SqlProcedure]
        public static void SQL2string(
            SqlString txt_query,
            int num_rows,
            int num_cols,
            int col_width,
            SqlString list_width,
            out SqlString response)
        {
            bool cw = list_width.ToString().Length > 0;

            List<int> widths = new List<int>();

            if (cw)
            {
                widths = new List<int>(Array.ConvertAll(list_width.ToString().Split(','), int.Parse));
            }

            string crn = "+", ln = "-", cl = "|",
                nl = System.Environment.NewLine;
            string result = "```" + nl;

            int col_counter = 0, row_counter = 0;


            //Get the select results
            var dt = new DataTable();
            using (var con = OpenContextConnection())
            {
                var cmd = new SqlCommand(txt_query.ToString(), con);
                var da = new SqlDataAdapter(cmd);
                da.Fill(dt);
            }

            // construct line separator
            var lin_sep = crn;
            foreach (DataColumn col in dt.Columns)
            {
                int wd = cw ? widths[col_counter] : col_width;
                lin_sep += new String(ln.ToCharArray()[0], wd) + crn;
                col_counter++;
                if (col_counter > num_cols) break;
            }
            //lin_sep += nl;

            // Construct the header
            result += cl;
            col_counter = 0;
            foreach (DataColumn col in dt.Columns)
            {
                int wd = cw ? widths[col_counter] : col_width;
                result += FormatString(col.ColumnName, wd) + cl;
                col_counter++;
                if (col_counter > num_cols) break;
            }
            result += nl + lin_sep;

            // Construct the body
            foreach (DataRow row in dt.Rows)
            {
                col_counter = 0;
                result += nl + cl;
                foreach (DataColumn col in dt.Columns)
                {
                    int wd = cw ? widths[col_counter] : col_width;
                    result += FormatString(row[col.ColumnName].ToString(), wd) + cl;
                    col_counter++;
                    if (col_counter > num_cols) break;
                }

                row_counter++;
                if (row_counter > num_rows) break;

            }

            result += nl + "```";
            response = result;
        }

        static SqlConnection OpenContextConnection()
        {
            SqlConnection connection = new SqlConnection("context connection=true");
            connection.Open();
            return connection;
        }

        static string FormatString(string str, int len = 10)
        {
            string cont = ">";

            if (str.Length > len)
            {
                return str.Substring(0, len - 1) + cont;
            }
            else
            {
                return str + new String(' ', len - str.Length);
            }

        }

        private static List<KeyValuePair<string, string>> GetHeaders(SqlXml headerXml)
        {
            List<KeyValuePair<string, string>> keyValuePairList = (List<KeyValuePair<string, string>>)null;
            if (headerXml != null && !headerXml.IsNull)
            {
                keyValuePairList = new List<KeyValuePair<string, string>>();
                using (XmlReader reader = headerXml.CreateReader())
                {
                    while (reader.Read())
                    {
                        if (reader.NodeType == XmlNodeType.Element && reader.Name == "Header")
                        {
                            string attribute1 = reader.GetAttribute("Name");
                            string attribute2 = reader.GetAttribute("Value");
                            keyValuePairList.Add(new KeyValuePair<string, string>(attribute1, attribute2));
                        }
                    }
                }
            }
            return keyValuePairList;
        }
    }
}

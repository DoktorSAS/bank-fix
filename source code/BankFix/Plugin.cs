using SharedLibraryCore;
using SharedLibraryCore.Interfaces;
using System;
using System.IO;
using System.Threading.Tasks;
using SharedLibraryCore.Configuration;
using System.Xml;
using System.Collections.Generic;
using SharedLibraryCore.Helpers;
using System.Text.RegularExpressions;
using static System.Net.Mime.MediaTypeNames;
using Newtonsoft.Json;
using System.Text;
using System.Threading.Tasks.Dataflow;
using System.Linq;
using SharedLibraryCore.Database.Models;

namespace AutomessageFeed
{
    public class Plugin : IPlugin
    {
        public string Name => "Bank Fix";

        public float Version => (float)Utilities.GetVersionAsDouble();

        public string Author => "Doktor SAS & fed";

        public class BankClient
        {
            public BankClient(long Guid)
            {
                this.Guid = Guid;
            } 
            public int Money = 0;
            public long Guid;
        }

        public class Bank
        {
            public List<BankClient> bankClients = new List<BankClient>();
        }

        public Bank bank = new Bank();

        public string path = Path.GetFullPath(Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, @"../Bank.json"));

        public BankClient InitializeBankClient(long Guid)
        {
            // Returns client or creates one
            for (int i = 0; i < bank.bankClients.Count; i++)
            {
                if (bank.bankClients[i].Guid == Guid)
                {
                    return bank.bankClients[i];
                }
            }
            BankClient client = new BankClient(Guid);
            bank.bankClients.Add(client);
            _ = WriteBank();
            return client;
        }

        public void SetBankDvars(Server S)
        {
            // Sets dvar with information about connected players' money
            string bankDvar = "";
            for (int i = 0; i < S.Clients.Count; i++)
            {
                if (S.Clients[i] == null)
                {
                    continue;
                }

                BankClient client = InitializeBankClient(S.Clients[i].NetworkId);
                bankDvar += (i > 0 ? "-" : "") + $"{S.Clients[i].NetworkId},{client.Money}";
            }
            S.RconParser.SetDvarAsync(S.RemoteConnection, "bank_clients_information", bankDvar);
        }

        public Task OnEventAsync(GameEvent E, Server S)
        {
            if (S.Gametype != "zclassic")
            {
                return Task.CompletedTask;
            }

            switch (E.Type)
            {
                case (GameEvent.EventType.PreConnect):
                case (GameEvent.EventType.Join):
                case (GameEvent.EventType.MapChange):
                    SetBankDvars(S);
                    break;
                case (GameEvent.EventType.Disconnect):
                    SetBankDvars(S);
                    break;
                case (GameEvent.EventType.Unknown):
                    if (Regex.Match(E.Data, @"IW4MBANK;(\d+);(\d+)").Length > 0)
                    {
                        string[] matchList = E.Data.Split(';');
                        BankClient client = InitializeBankClient(Convert.ToInt64(matchList[1]));
                        client.Money = Convert.ToInt32(matchList[2]);
                        SetBankDvars(S);
                    }

                    if (Regex.Match(E.Data, @"IW4MBANK_ALL;(.)+").Length > 0)
                    {
                        // Game ends, parses json string from logfile cotaining players' account_value and guid
                        string json = E.Data.Substring(13);
                        List<BankClient> bankClients = JsonConvert.DeserializeObject<List<BankClient>>(json);

                        // Saves it to memory and file
                        foreach (BankClient client in bankClients)
                        {
                            BankClient _client = InitializeBankClient(client.Guid);
                            _client.Money = Convert.ToInt32(client.Money);
                        }
                        SetBankDvars(S);
                        _ = WriteBank();
                    }
                    break;
            }

            return Task.CompletedTask;
        }

        public async Task WriteBank()
        {
            // Saves data to file
            FileStream file = File.OpenWrite(path);
            byte[] json = new UTF8Encoding(true).GetBytes(JsonConvert.SerializeObject(bank));
            file.Write(json, 0, json.Length);
            return;
        }

        public async Task OnLoadAsync(IManager manager)
        {
            try
            {
                if (!File.Exists(path))
                {
                    // Creates file
                    FileStream file = File.Create(path);
                    byte[] _json = new UTF8Encoding(true).GetBytes(JsonConvert.SerializeObject(bank));
                    file.Write(_json, 0, _json.Length);
                    return;
                }

                // Loads file
                string json = File.ReadAllText(path);

                bank = JsonConvert.DeserializeObject<Bank>(json);

                Console.WriteLine($"BankFix loaded ({Author})");
            }
            catch (Exception e)
            {
                Console.WriteLine($"BankFix not loaded, make sure you didn't mess up the json file: {e}");
            }
        }

        public Task OnTickAsync(Server S)
        {
            throw new NotImplementedException();
        }

        public Task OnUnloadAsync()
        {
            WriteBank();
            return Task.CompletedTask;
        }
    }
}
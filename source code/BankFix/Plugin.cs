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

        private readonly IMetaService _metaService;

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

        public Plugin(IConfigurationHandlerFactory configurationHandlerFactory, ITranslationLookup translationLookup, IMetaService metaService)
        {
            _metaService = metaService;
        }

        public async Task<int> GetBankMeta(EFClient C)
        {
            if (await _metaService.GetPersistentMeta("BankBalance", C) == null)
            {
                _ = _metaService.AddPersistentMeta("BankBalance", "0", C);
                return 0;
            }
            return Convert.ToInt32((await _metaService.GetPersistentMeta("BankBalance", C)).Value);
        }

        public async Task SetBankMeta(EFClient C, int Money)
        {
            await _metaService.AddPersistentMeta("BankBalance", Money.ToString(), C);
        }

        public async Task SetBankDvars(Server S)
        {
            // Sets dvar with information about connected players' money
            string bankDvar = "";
            for (int i = 0; i < S.Clients.Count; i++)
            {
                if (S.Clients[i] == null)
                {
                    continue;
                }
                bankDvar += (i > 0 ? "-" : "") + $"{S.Clients[i].NetworkId},{await GetBankMeta(S.Clients[i])}";
            }
            _ = S.RconParser.SetDvarAsync(S.RemoteConnection, "bank_clients_information", bankDvar);
        }


        public async Task OnEvent(GameEvent E, Server S)
        {
            if (S.Gametype != "zclassic")
            {
                return;
            }

            switch (E.Type)
            {
                case (GameEvent.EventType.PreConnect):
                case (GameEvent.EventType.Join):
                case (GameEvent.EventType.MapChange):
                    _ = SetBankDvars(S);
                    break;
                case (GameEvent.EventType.Disconnect):
                    _ = SetBankDvars(S);
                    break;
                case (GameEvent.EventType.Unknown):
                    if (Regex.Match(E.Data, @"IW4MBANK;(\d+);(\d+)").Length > 0)
                    {
                        // Saves bank account values
                        string[] matchList = E.Data.Split(';');
                        EFClient C = S.GetClientsAsList().Find(c => c.NetworkId == Convert.ToInt64(matchList[1]));
                        await SetBankMeta(C, Convert.ToInt32(matchList[2]));
                        _ = SetBankDvars(S);
                    }

                    if (Regex.Match(E.Data, @"IW4MBANK_ALL;(.)+").Length > 0)
                    {
                        // Game ends, saves bank account values
                        string json = E.Data.Substring(13);
                        List<BankClient> bankClients = JsonConvert.DeserializeObject<List<BankClient>>(json);

                        foreach (BankClient client in bankClients)
                        {
                            EFClient C = S.GetClientsAsList().Find(c => c.NetworkId == Convert.ToInt64(client.Guid));
                            await SetBankMeta(C, client.Money);
                        }
                        _ = SetBankDvars(S);
                    }
                    break;
            }
        }

        public Task OnEventAsync(GameEvent E, Server S)
        {
            _ = OnEvent(E, S);
            return Task.CompletedTask;
        }

        public Task OnLoadAsync(IManager manager)
        {
            Console.WriteLine($"BankFix loaded ({Author})");
        }

        public Task OnTickAsync(Server S)
        {
            throw new NotImplementedException();
        }

        public Task OnUnloadAsync()
        {
            return Task.CompletedTask;
        }
    }
}

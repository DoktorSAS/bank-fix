using System.Globalization;
using System.Text.RegularExpressions;
using Newtonsoft.Json;
using SharedLibraryCore;
using SharedLibraryCore.Interfaces;

namespace BankFix;

public class Plugin : IPlugin
{
    public string Name => "Bank Fix";
    public float Version => (float)Utilities.GetVersionAsDouble();
    public string Author => "Doktor SAS & fed";
    public const string BankBalanceKey = "BankBalance";
    public static BankManager BankManager { get; private set; } = null!;


    public Plugin(IServiceProvider serviceProvider)
    {
        BankManager = new BankManager(serviceProvider);
    }

    public async Task OnEventAsync(GameEvent gameEvent, Server server)
    {
        if (server.Gametype != "zclassic") return;

        switch (gameEvent.Type)
        {
            case GameEvent.EventType.Join:
            case GameEvent.EventType.MapChange:
                await BankManager.SetBankDVars(server);
                break;
            case GameEvent.EventType.Disconnect:
                await BankManager.SetBankDVars(server);
                break;
            case GameEvent.EventType.Unknown:
                if (Regex.Match(gameEvent.Data, @"IW4MBANK;(\d+);(\d+)").Length > 0)
                {
                    // Saves bank account values - MATCHLIST = GUID ; BANK BALANCE
                    var matchList = gameEvent.Data.Split(';');
                    var client = server.GetClientsAsList()
                        .Find(client => client.NetworkId == Convert.ToInt64(matchList[1]));
                    if (client is null) return;
                    await BankManager.SetBankMeta(client, int.Parse(matchList[2]));
                    await BankManager.SetBankDVars(server);
                }

                if (Regex.Match(gameEvent.Data, @"IW4MBANK_ALL;(.)+").Length > 0)
                {
                    // Game ends, saves bank account values
                    var json = gameEvent.Data[13..];
                    var bankClients = JsonConvert.DeserializeObject<List<BankClient>>(json);
                    if (bankClients is null) return;

                    var bankClientsDict = bankClients
                        .GroupBy(client => client.Guid)
                        .ToDictionary(key => key.Key
                            .ConvertGuidToLong(NumberStyles.Integer), value => value.First().Money);

                    foreach (var client in gameEvent.Owner.Manager.GetActiveClients()
                                 .Where(client => bankClientsDict.ContainsKey(client.NetworkId)))
                    {
                        await BankManager.SetBankMeta(client, bankClientsDict[client.NetworkId]);
                    }

                    await BankManager.SetBankDVars(server);
                }

                break;
        }
    }

    public Task OnLoadAsync(IManager manager)
    {
        Console.WriteLine($"BankFix loaded ({Author})");
        return Task.CompletedTask;
    }

    public Task OnTickAsync(Server server)
    {
        return Task.CompletedTask;
    }

    public Task OnUnloadAsync()
    {
        return Task.CompletedTask;
    }
}

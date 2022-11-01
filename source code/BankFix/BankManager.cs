using SharedLibraryCore.Database.Models;
using Microsoft.Extensions.DependencyInjection;
using SharedLibraryCore;
using SharedLibraryCore.Interfaces;

namespace BankFix;

public class BankManager
{
    private readonly IMetaServiceV2 _metaService;

    public BankManager(IServiceProvider serviceProvider)
    {
        _metaService = serviceProvider.GetRequiredService<IMetaServiceV2>();
    }

    private async Task<int> GetBankMeta(EFClient efClient)
    {
        var balance = await _metaService.GetPersistentMeta(Plugin.BankBalanceKey, efClient.ClientId);
        if (balance is not null) return int.Parse(balance.Value);
        await _metaService.SetPersistentMetaValue(Plugin.BankBalanceKey, "0", efClient.ClientId);
        return 0;
    }

    public async Task SetBankMeta(EFClient efClient, int money) =>
        await _metaService.SetPersistentMetaValue("BankBalance", money.ToString(), efClient.ClientId);

    public async Task SetBankDVars(Server server)
    {
        // Sets dvar with information about connected players' money
        var bankDVar = string.Empty;
        for (var i = 0; i < server.Clients.Count; i++)
        {
            if (server.Clients[i] == null) continue;

            bankDVar += (i > 0 ? "-" : "") + $"{server.Clients[i].NetworkId},{await GetBankMeta(server.Clients[i])}";
        }

        await server.RconParser.SetDvarAsync(server.RemoteConnection, "bank_clients_information", bankDVar);
    }
}

// ReSharper disable once ClassNeverInstantiated.Global
public class BankClient
{
    public string? Guid { get; set; }
    public int Money { get; set; }
}

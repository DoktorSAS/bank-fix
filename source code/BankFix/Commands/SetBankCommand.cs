using Data.Models.Client;
using SharedLibraryCore;
using SharedLibraryCore.Commands;
using SharedLibraryCore.Configuration;
using SharedLibraryCore.Interfaces;

namespace BankFix.Commands;

public class SetBankCommand : Command
{
    public SetBankCommand(CommandConfiguration config, ITranslationLookup translationLookup) : base(config,
        translationLookup)
    {
        Name = "setbank";
        Description = "set a players bank";
        Alias = "sb";
        Permission = EFClient.Permission.SeniorAdmin;
        RequiresTarget = true;
        Arguments = new[]
        {
            new CommandArgument
            {
                Name = translationLookup["COMMANDS_ARGS_PLAYER"],
                Required = true
            }
        };
    }

    public override async Task ExecuteAsync(GameEvent gameEvent)
    {
        var parsed = int.TryParse(gameEvent.Data, out var amount);
        if (!parsed)
        {
            gameEvent.Origin.Tell("Input provided is not a number");
            return;
        }

        await Plugin.BankManager.SetBankMeta(gameEvent.Target, amount);
        await Plugin.BankManager.SetBankDVars(gameEvent.Owner);
        gameEvent.Origin.Tell($"Set {gameEvent.Target.Name}'s bank to {amount}");
    }
}

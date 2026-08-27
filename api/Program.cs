using Microsoft.Data.Sqlite;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var dbPath = Path.Combine(app.Environment.ContentRootPath, "rota.db");

InitDb(dbPath);

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/api/rota", () =>
{
    using var conn = new SqliteConnection($"Data Source={dbPath}");
    conn.Open();
    using var cmd = conn.CreateCommand();
    cmd.CommandText = "SELECT state FROM rota WHERE id = 1";
    var result = cmd.ExecuteScalar() as string;
    return Results.Content(result ?? "{}", "application/json");
});

app.MapPost("/api/rota", async (HttpRequest request) =>
{
    using var reader = new StreamReader(request.Body);
    var json = await reader.ReadToEndAsync();
    using var conn = new SqliteConnection($"Data Source={dbPath}");
    conn.Open();
    using var cmd = conn.CreateCommand();
    cmd.CommandText = "UPDATE rota SET state = @s, updated_at = datetime('now') WHERE id = 1";
    cmd.Parameters.AddWithValue("@s", json);
    cmd.ExecuteNonQuery();
    return Results.Ok();
});

app.MapFallback(context =>
{
    context.Response.ContentType = "text/html";
    return context.Response.SendFileAsync(
        Path.Combine(app.Environment.WebRootPath, "index.html"));
});

app.Run();

static void InitDb(string path)
{
    using var conn = new SqliteConnection($"Data Source={path}");
    conn.Open();
    using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        CREATE TABLE IF NOT EXISTS rota (
            id INTEGER PRIMARY KEY,
            state TEXT NOT NULL DEFAULT '{}',
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );
        INSERT OR IGNORE INTO rota (id, state) VALUES (1, '{}');
        """;
    cmd.ExecuteNonQuery();
}

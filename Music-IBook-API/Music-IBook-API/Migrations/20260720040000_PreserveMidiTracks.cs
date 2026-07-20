using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Music_IBook_API.Models;

#nullable disable

namespace Music_IBook_API.Migrations;

[DbContext(typeof(MusicIBookDbContext))]
[Migration("20260720040000_PreserveMidiTracks")]
public partial class PreserveMidiTracks : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "TempoMap",
            table: "Lessons",
            type: "nvarchar(max)",
            nullable: false,
            defaultValue: "");

        migrationBuilder.AddColumn<int>(
            name: "Track",
            table: "LessonNotes",
            type: "int",
            nullable: false,
            defaultValue: 0);

        migrationBuilder.AddColumn<string>(
            name: "TrackName",
            table: "LessonNotes",
            type: "nvarchar(max)",
            nullable: false,
            defaultValue: "");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "TempoMap", table: "Lessons");
        migrationBuilder.DropColumn(name: "Track", table: "LessonNotes");
        migrationBuilder.DropColumn(name: "TrackName", table: "LessonNotes");
    }
}

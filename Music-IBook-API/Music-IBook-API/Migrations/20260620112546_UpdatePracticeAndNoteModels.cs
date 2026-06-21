using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class UpdatePracticeAndNoteModels : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "TimeOffsetMs",
                table: "StudentNoteAttempts",
                newName: "TimingErrorMs");

            migrationBuilder.RenameColumn(
                name: "PlayedSecond",
                table: "StudentNoteAttempts",
                newName: "PlayedAtSecond");

            migrationBuilder.RenameColumn(
                name: "ExpectedSecond",
                table: "StudentNoteAttempts",
                newName: "ExpectedAtSecond");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAtUtc",
                table: "StudentNoteAttempts",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAtUtc",
                table: "PracticeSessions",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "DurationSeconds",
                table: "PracticeSessions",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsExam",
                table: "PracticeSessions",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "StudentNoteAttempts");

            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "PracticeSessions");

            migrationBuilder.DropColumn(
                name: "DurationSeconds",
                table: "PracticeSessions");

            migrationBuilder.DropColumn(
                name: "IsExam",
                table: "PracticeSessions");

            migrationBuilder.RenameColumn(
                name: "TimingErrorMs",
                table: "StudentNoteAttempts",
                newName: "TimeOffsetMs");

            migrationBuilder.RenameColumn(
                name: "PlayedAtSecond",
                table: "StudentNoteAttempts",
                newName: "PlayedSecond");

            migrationBuilder.RenameColumn(
                name: "ExpectedAtSecond",
                table: "StudentNoteAttempts",
                newName: "ExpectedSecond");
        }
    }
}

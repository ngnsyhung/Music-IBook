using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class PreserveMidiNotationTiming : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Tempo",
                table: "Lessons",
                type: "int",
                nullable: false,
                defaultValue: 80);

            migrationBuilder.AddColumn<double>(
                name: "DurationBeat",
                table: "LessonNotes",
                type: "float",
                nullable: false,
                defaultValue: 1.0);

            migrationBuilder.AddColumn<double>(
                name: "StartBeat",
                table: "LessonNotes",
                type: "float",
                nullable: false,
                defaultValue: 1.0);

            migrationBuilder.AddColumn<int>(
                name: "Velocity",
                table: "LessonNotes",
                type: "int",
                nullable: false,
                defaultValue: 90);

            // Dữ liệu cũ chưa có beat riêng. Giữ cách hiển thị cũ bằng cách
            // dùng Second làm mốc ban đầu và khôi phục trường độ từ tên nốt.
            migrationBuilder.Sql(
                """
                UPDATE [LessonNotes]
                SET [StartBeat] = CASE WHEN [Second] > 0 THEN [Second] ELSE 1 END,
                    [DurationBeat] = CASE [Duration]
                        WHEN 'whole' THEN 4.0
                        WHEN 'dotted_half' THEN 3.0
                        WHEN 'half' THEN 2.0
                        WHEN 'dotted_quarter' THEN 1.5
                        WHEN 'quarter' THEN 1.0
                        WHEN 'quarter_triplet' THEN 0.6666666667
                        WHEN 'dotted_eighth' THEN 0.75
                        WHEN 'eighth' THEN 0.5
                        WHEN 'eighth_triplet' THEN 0.3333333333
                        WHEN 'dotted_sixteenth' THEN 0.375
                        WHEN 'sixteenth' THEN 0.25
                        WHEN 'sixteenth_triplet' THEN 0.1666666667
                        WHEN 'thirty_second' THEN 0.125
                        WHEN 'sixty_fourth' THEN 0.0625
                        ELSE 1.0
                    END;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Tempo",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "DurationBeat",
                table: "LessonNotes");

            migrationBuilder.DropColumn(
                name: "StartBeat",
                table: "LessonNotes");

            migrationBuilder.DropColumn(
                name: "Velocity",
                table: "LessonNotes");
        }
    }
}

using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MusicSystem.Backend.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "user_profiles",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    firebase_uid = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    role = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    subscription_plan = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    avatar_url = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    nickname = table.Column<string>(type: "text", nullable: true),
                    search_name = table.Column<string>(type: "text", nullable: true),
                    pix_key = table.Column<string>(type: "text", nullable: true),
                    bio = table.Column<string>(type: "text", nullable: true),
                    instagram_url = table.Column<string>(type: "text", nullable: true),
                    youtube_url = table.Column<string>(type: "text", nullable: true),
                    facebook_url = table.Column<string>(type: "text", nullable: true),
                    gallery_urls = table.Column<List<string>>(type: "text[]", nullable: true),
                    fcm_token = table.Column<string>(type: "text", nullable: true),
                    followers_count = table.Column<int>(type: "integer", nullable: false),
                    following_count = table.Column<int>(type: "integer", nullable: false),
                    unread_messages_count = table.Column<int>(type: "integer", nullable: false),
                    profile_views_count = table.Column<int>(type: "integer", nullable: false),
                    is_live = table.Column<bool>(type: "boolean", nullable: false),
                    live_until = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    last_active_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    birth_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    verification_level = table.Column<string>(type: "text", nullable: false),
                    is_parental_consent_granted = table.Column<bool>(type: "boolean", nullable: false),
                    is_dob_visible = table.Column<bool>(type: "boolean", nullable: false),
                    is_pix_visible = table.Column<bool>(type: "boolean", nullable: false),
                    profile_type = table.Column<string>(type: "text", nullable: true),
                    sub_type = table.Column<string>(type: "text", nullable: true),
                    artist_score = table.Column<int>(type: "integer", nullable: true),
                    professional_level = table.Column<string>(type: "text", nullable: true),
                    min_suggested_cache = table.Column<double>(type: "double precision", nullable: true),
                    max_suggested_cache = table.Column<double>(type: "double precision", nullable: true),
                    show_professional_badge = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_profiles", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_user_profiles_email",
                table: "user_profiles",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_user_profiles_firebase_uid",
                table: "user_profiles",
                column: "firebase_uid",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "user_profiles");
        }
    }
}

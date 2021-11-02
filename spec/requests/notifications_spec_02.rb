require "rails_helper"

RSpec.describe "NotificationsIndex02", type: :request do
  include ActionView::Helpers::DateHelper

  let(:staff_account) { create(:user) }
  let(:mascot_account) { create(:user) }
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    allow(User).to receive(:staff_account).and_return(staff_account)
    allow(User).to receive(:mascot_account).and_return(mascot_account)
  end

  def has_both_names(response_body)
    response_body.include?(CGI.escapeHTML(User.last.name)) &&
      response_body.include?(CGI.escapeHTML(User.second_to_last.name))
  end

  def renders_article_path(article)
    expect(response.body).to include article.path
  end

  def renders_authors_name(article)
    expect(response.body).to include CGI.escapeHTML(article.user.name)
  end

  def renders_article_published_at(article)
    expect(response.body).to include time_ago_in_words(article.published_at)
  end

  def renders_comments_html(comment)
    expect(response.body).to include comment.processed_html
  end

  describe "GET /notifications" do
    context "when a user's organization has a new comment notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, :with_notification_subscription, user: user, organization: organization) }
      let(:comment)  { create(:comment, user: user2, commentable: article) }
      let(:other_org) { create(:organization) }
      let(:other_org_article) { create(:article, :with_notification_subscription, user: user, organization: other_org) }
      let(:other_org_comment) { create(:comment, user: user2, commentable: other_org_article) }

      before do
        sign_in user
      end

      it "renders the correct message data", :aggregate_failures do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include("commented on")
        expect(response.body).not_to include("replied to a thread in")
        expect(response.body).not_to include("As a trusted member")
        renders_article_path(article)
        renders_comments_html(comment)
      end

      it "renders the reaction as previously reacted if it was reacted on" do
        Notification.send_new_comment_notifications_without_delay(comment)
        Reaction.create(user: user, reactable: comment, category: "like")

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).to include("reaction-button reacted")
      end

      it "does not render the reaction as reacted if it was not reacted on" do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :org, org_id: organization.id)
        expect(response.body).not_to include("reaction-button reacted")
      end

      it "does not render notifications if missing :org_id" do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :org)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.filter_map(&:organization_id).size).to eq(0)
      end

      it "does not render notifications belonging to other orgs" do
        Notification.send_new_comment_notifications_without_delay(other_org_comment)

        get notifications_path(filter: :org, org_id: other_org.id)
        notifications = controller.instance_variable_get(:@notifications)
        expect(notifications.filter_map(&:organization_id).size).to eq(0)
      end

      it "does render notifications belonging to other orgs if admin" do
        user.add_role(:super_admin)
        sign_in user

        Notification.send_new_comment_notifications_without_delay(other_org_comment)

        get notifications_path(filter: :org, org_id: other_org.id)
        expect(response.body).to include("commented on")
      end

      it "does render the proper message for a single notification if :filter is comments" do
        Notification.send_new_comment_notifications_without_delay(comment)

        get notifications_path(filter: :comments, org_id: organization.id)
        expect(response.body).to include("commented on")
      end
    end

    context "when a user has a new second level comment notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, :with_notification_subscription, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }
      let(:second_comment) do
        create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article",
                         parent_id: comment.id)
      end
      let(:third_comment) do
        create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article",
                         parent_id: second_comment.id)
      end

      before do
        sign_in user
        Notification.send_new_comment_notifications_without_delay(comment)
        Notification.send_new_comment_notifications_without_delay(second_comment)
        Notification.send_new_comment_notifications_without_delay(third_comment)
        get "/notifications"
      end

      it "renders comment notification text properly", :aggregate_failures do
        expect(response.body).to include "replied to a thread in"
        expect(response.body).to include CGI.escapeHTML("Re")
        expect(response.body).to include CGI.escapeHTML(comment.title.to_s)
      end
    end

    context "when a user has a new moderation notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        user.add_role(:trusted)
        sign_in user
        sidekiq_perform_enqueued_jobs do
          Notification.send_moderation_notification(comment)
        end
        get "/notifications"
      end

      it "renders the proper message data", :aggregate_failures do
        expect(response.body).to include "Since they are new to the community, could you leave a nice reply"
        renders_article_path(article)
        renders_comments_html(comment)
      end
    end

    context "when a user should not receive moderation notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        sign_in user
        sidekiq_perform_enqueued_jobs do
          Notification.send_moderation_notification(comment)
        end
        get "/notifications"
      end

      it "does not render the notification message", :aggregate_failures do
        expect(response.body).not_to include "Since they are new to the community, could you leave a nice reply"
        expect(response.body).not_to include article.path
        expect(response.body).not_to include comment.processed_html
      end
    end

    context "when a user has unsubscribed from mod roundrobin notifications" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment)  { create(:comment, user_id: user2.id, commentable_id: article.id, commentable_type: "Article") }

      before do
        user.add_role(:trusted)
        user.notification_setting.update(mod_roundrobin_notifications: false)
        sign_in user
        sidekiq_perform_enqueued_jobs do
          Notification.send_moderation_notification(comment)
        end
        get "/notifications"
      end

      it "does not render the proper message", :aggregate_failures do
        expect(response.body).not_to include "Since they are new to the community, could you leave a nice reply"
        expect(response.body).not_to include article.path
        expect(response.body).not_to include comment.processed_html
      end
    end

    context "when user is trusted" do
      let(:user) { create(:user, :trusted) }
      let(:reaction) { create(:thumbsdown_reaction, user: user) }
      let(:like_reaction) { create(:reaction, user: user) }

      it "allow sees thumbsdown category" do
        sign_in user
        Notification.send_reaction_notification_without_delay(reaction, user)
        get "/notifications"
        expect(response.body).to include("Notifications")
      end

      it "does not show notification" do
        other_user = create(:user)
        sign_in other_user
        Notification.send_reaction_notification_without_delay(reaction, other_user)
        Notification.send_reaction_notification_without_delay(like_reaction, other_user)
        get "/notifications"
        expect(response.body).to include("Like")
        expect(response.body).not_to include("Thumbsdown")
      end
    end

    context "when a user has a new welcome notification" do
      let(:active_broadcast) { create(:set_up_profile_broadcast) }
      let(:inactive_broadcast) { create(:set_up_profile_broadcast, active: false) }

      before { sign_in user }

      it "renders a welcome notification if the broadcast is active" do
        sidekiq_perform_enqueued_jobs do
          Notification.send_welcome_notification(user.id, active_broadcast.id)
        end
        get "/notifications"
        expect(response.body).to include active_broadcast.processed_html
      end

      it "does not render a welcome notification if the broadcast is inactive" do
        sidekiq_perform_enqueued_jobs do
          Notification.send_welcome_notification(user.id, inactive_broadcast.id)
        end
        get "/notifications"
        expect(response.body).not_to include inactive_broadcast.processed_html
      end
    end

    context "when a user has a new badge notification w/o credits" do
      before do
        sign_in user
        badge = create(:badge, credits_awarded: 0)
        badge_achievement = create(:badge_achievement, user: user, badge: badge)
        sidekiq_perform_enqueued_jobs do
          Notification.send_new_badge_achievement_notification(badge_achievement)
        end
        get "/notifications"
      end

      it "renders the correct badge's notification", :aggregate_failures do
        renders_title
        renders_correct_message(user)
        renders_correct_description
        renders_visit_profile_button
      end

      def renders_title
        expect(response.body).to include Badge.first.title
      end

      def renders_correct_message(user)
        expect(response.body).to include user.badge_achievements.first.rewarding_context_message
      end

      def renders_correct_description
        expect(response.body).to include CGI.escapeHTML(Badge.first.description)
      end

      def renders_visit_profile_button
        expect(response.body).to include "Visit your profile"
      end

      it "has no information about credits" do
        expect(response.body).not_to include "new credits"
      end
    end

    context "when a user has a new badge notification with credits" do
      before do
        sign_in user
        badge = create(:badge, credits_awarded: 11)
        badge_achievement = create(:badge_achievement, user: user, badge: badge)
        sidekiq_perform_enqueued_jobs do
          Notification.send_new_badge_achievement_notification(badge_achievement)
        end
        get "/notifications"
      end

      it "renders information about credits" do
        expect(response.body).to include "11 new credits"
      end
    end

    context "when a user has a new comment mention notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }
      let(:comment) do
        create(
          :comment,
          user_id: user2.id,
          commentable_id: article.id,
          commentable_type: "Article",
          body_markdown: "@#{user.username}",
        )
      end
      let(:mention) { create(:mention, mentionable: comment, user: user) }

      before do
        sidekiq_perform_enqueued_jobs do
          Notification.send_mention_notification(mention)
        end
        sign_in user
        get "/notifications"
      end

      it "renders the proper message" do
        expect(response.body).to include "mentioned you in a comment"
        renders_comments_html(comment)
      end
    end

    context "when a user has a new article mention notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user2.id) }
      let(:mention)  { create(:mention, mentionable: article, user: user) }

      before do
        article.update!(body_markdown: "Hello, @#{user.username}!")
        sidekiq_perform_enqueued_jobs do
          Notification.send_mention_notification(mention)
        end
        sign_in user
        get "/notifications"
      end

      it "renders the proper message" do
        expect(response.body).to include "mentioned you in a post"
        renders_article_path(article)
        renders_authors_name(article)
        renders_article_published_at(article)
      end
    end

    context "when a user has a new article created notification" do
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }

      before do
        user2.follow(user)
        sidekiq_perform_enqueued_jobs do
          Notification.send_to_mentioned_users_and_followers(article)
        end
        sign_in user2
        get "/notifications"
      end

      it "renders the proper message", :aggregate_failures do
        expect(response.body).to include "made a new post"
        renders_article_path(article)
        renders_authors_name(article)
        renders_article_published_at(article)
      end

      it "renders the reaction as previously reacted if it was reacted on" do
        Reaction.create(user: user2, reactable: article, category: "like")
        get "/notifications"
        expect(response.body).to include "reaction-button reacted"
      end

      it "does not render the reaction as reacted if it was not reacted on" do
        expect(response.body).not_to include "reaction-button reacted"
      end
    end

    context "when a user is an admin" do
      let(:admin) { create(:user, :super_admin) }
      let(:user2)    { create(:user) }
      let(:article)  { create(:article, user_id: user.id) }

      before do
        user2.follow(user)
        sidekiq_perform_enqueued_jobs do
          Notification.send_to_mentioned_users_and_followers(article)
        end
        sign_in admin
      end

      it "can view other people's notifications" do
        get "/notifications?username=#{user2.username}"
        expect(response.body).to include "made a new post"
      end
    end

    context "when filter is unknown" do
      it "does not raise an error" do
        sign_in user
        expect { get "/notifications/feed" }.not_to raise_error
      end
    end
  end
end

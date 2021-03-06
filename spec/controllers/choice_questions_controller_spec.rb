require 'spec_helper'

describe ChoiceQuestionsController do
  include Authlogic::TestCase

  let(:site) { create :site }
  let(:survey) { create :survey, { site: site } }
  let(:survey_version) { create :survey_version, { survey: survey } }
  let(:choice_question) { mock_model(ChoiceQuestion) }

  before do
    activate_authlogic
    user = User.create(email: "email@example.com", password: "password", password_confirmation: "password", f_name: "example", l_name: "user")
    user.sites << site
    UserSession.create user

    User.any_instance.stub_chain(:surveys, :find).and_return(survey)
    Survey.any_instance.stub_chain(:survey_versions, :find).and_return(survey_version)
  end

  context 'new' do
    before do
      survey_version.stub_chain(:choice_questions, :build).and_return(choice_question)
      controller.stub(:build_default_choice_context)
    end

    it 'should build a new ChoiceQuestion' do
      survey_version.choice_questions.should_receive(:build).and_return(choice_question)
      get :new, survey_id: survey.id, survey_version_id: survey_version.id
    end

    it 'should render new' do
      get :new, survey_id: survey.id, survey_version_id: survey_version.id
      response.should render_template(:new)
    end

    it 'should render new.js' do
      get :new, survey_id: survey.id, survey_version_id: survey_version.id, format: :js
      response.should render_template(:new)
    end
  end

  context 'create' do
    before do
      ChoiceQuestion.stub(:new).and_return(choice_question)
      choice_question.stub_chain(:survey_element, :survey_version_id=)
      controller.stub(:build_default_choice_context)
    end

    context 'valid choice question' do
      before { choice_question.stub(:save).and_return true }

      it 'should create a new ChoiceQuestion' do
        ChoiceQuestion.should_receive(:new).and_return(choice_question)
        post :create, survey_id: survey.id, survey_version_id: survey_version.id
      end

      it 'should assign survey_version_id to SurveyElement of ChoiceQuestion' do
        survey_element_double = double
        choice_question.stub(:survey_element).and_return(survey_element_double)
        survey_element_double.should_receive(:survey_version_id=)
        post :create, survey_id: survey.id, survey_version_id: survey_version.id
      end

      it 'should redirect to show survey with message' do
        post :create, survey_id: survey.id, survey_version_id: survey_version.id
        response.should redirect_to(survey_path survey)
        flash[:notice].should =~ /Successfully added choice question./i
      end

      it 'should render element_create.js' do
        post :create, survey_id: survey.id, survey_version_id: survey_version.id, format: :js
        response.should render_template('shared/_element_create')
      end
    end

    it 'should render new if validation fails' do
      choice_question.stub(:save).and_return false
      post :create, survey_id: survey.id, survey_version_id: survey_version.id
      response.should render_template(:new)
    end
  end

  context 'edit' do
    it 'should ask the SurveyVersion for the appropriate ChoiceQuestion' do
      choice_questions_double = double
      survey_version.stub(:choice_questions).and_return(choice_questions_double)

      choice_questions_double.should_receive(:find)

      get :edit, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id
    end

    it 'should render edit' do
      survey_version.stub_chain(:choice_questions, :find)

      get :edit, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id

      response.should render_template(:edit)
    end

    it 'should render edit.js' do
      survey_version.stub_chain(:choice_questions, :find)

      get :edit, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id, format: :js

      response.should render_template(:edit)
    end
  end

  context 'update' do
    before(:each) do
      ChoiceQuestion.stub(:find).and_return(choice_question)
    end

    it 'should render edit if validation fails' do
      choice_question.stub(:update_attributes).and_return false

      put :update, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id

      response.should render_template(:edit)
    end

    it 'should redirect to show survey with message' do
      choice_question.stub(:update_attributes).and_return true

      put :update, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id

      response.should redirect_to(survey_path survey)
      flash[:notice].should =~ /Successfully updated choice question./i
    end

    it 'should render element_create.js' do
      choice_question.stub(:update_attributes)

      put :update, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id, format: :js

      response.should render_template('shared/_element_create')
    end

    it 'should mark the survey_version reports dirty if survey_version is published' do
      choice_question.stub(:update_attributes).and_return true
      survey_version.stub(:published?).and_return true
      survey_version.should_receive :mark_reports_dirty!
      put :update, survey_id: survey.id, survey_version_id: survey_version.id,
        id: choice_question.id
    end

    it 'should not mark the survey version reports dirt if the survey version is not published' do

    end
  end

  context 'destroy' do
    before do
      ChoiceQuestion.stub(:find).and_return(choice_question)
      controller.stub(:destroy_default_rule_and_display_field)
      choice_question.stub(:destroy)
    end

    it 'should call for destruction of the ChoiceQuestion' do
      choice_question.should_receive(:destroy)
      delete :destroy, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id
    end

    it 'should redirect to show survey with message' do
      delete :destroy, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id

      response.should redirect_to(survey_path survey)
      flash[:notice].should =~ /Successfully deleted choice question./i
    end

    it 'should render element_destroy.js' do
      delete :destroy, survey_id: survey.id, survey_version_id: survey_version.id, id: choice_question.id, format: :js
      response.should render_template('shared/_element_destroy')
    end
  end
end

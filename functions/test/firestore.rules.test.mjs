import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  documentId,
  doc,
  getDocs,
  getDoc,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  startAfter,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-habi-rules-test';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/seeker'), { uid: 'seeker', role: 'jobSeeker', displayName: 'Seeker' });
    await setDoc(doc(db, 'users/other'), { uid: 'other', role: 'jobSeeker', displayName: 'Other Member' });
    await setDoc(doc(db, 'users/private'), { uid: 'private', role: 'jobSeeker', displayName: 'Private Member' });
    await setDoc(doc(db, 'users/employer'), { uid: 'employer', role: 'employer', displayName: 'Employer' });
    await setDoc(doc(db, 'users/admin'), { uid: 'admin', role: 'jobSeeker', displayName: 'Admin' });
    await setDoc(doc(db, 'users/suspended'), { uid: 'suspended', role: 'jobSeeker', displayName: 'Suspended', accountStatus: 'suspended' });
    await setDoc(doc(db, 'admin_user_directory/seeker'), { uid: 'seeker', email: 'seeker@example.com', displayName: 'Seeker', role: 'jobSeeker', accountStatus: 'active', createdAt: new Date('2025-01-01T00:00:00Z'), updatedAt: new Date('2025-01-01T00:00:00Z') });
    await setDoc(doc(db, 'admin_user_directory/other'), { uid: 'other', email: 'other@example.com', displayName: 'Other Member', role: 'jobSeeker', accountStatus: 'active', createdAt: new Date('2025-01-01T00:00:00Z'), updatedAt: new Date('2025-01-01T00:00:00Z') });
    await setDoc(doc(db, 'employer_profiles/employer'), { uid: 'employer', verificationStatus: 'verified' });
    await setDoc(doc(db, 'seeker_profiles/seeker'), { uid: 'seeker', visibility: true });
    await setDoc(doc(db, 'seeker_profiles/other'), { uid: 'other', visibility: true });
    await setDoc(doc(db, 'seeker_profiles/private'), { uid: 'private', visibility: false });
    await setDoc(doc(db, 'jobs/approved'), { ownerId: 'employer', status: 'published', moderationStatus: 'approved', title: 'Approved role' });
    await setDoc(doc(db, 'jobs/approved-flow'), { ownerId: 'employer', status: 'published', moderationStatus: 'approved', title: 'Workflow role' });
    await setDoc(doc(db, 'jobs/pending'), { ownerId: 'employer', status: 'published', moderationStatus: 'pending_review', title: 'Pending role' });
    await setDoc(doc(db, 'jobs/draft'), { ownerId: 'employer', status: 'draft', title: 'Draft role' });
    const project = (ownerUid, status) => ({
      ownerUid, title: 'Portfolio project', summary: 'A short summary',
      description: 'A project description', category: 'Design', role: 'Designer',
      skills: ['Design'], technologies: ['Flutter'], responsibilities: '',
      outcomes: '', reflection: '', startedAt: new Date('2025-01-01T00:00:00Z'),
      endedAt: null, ongoing: true, demoUrl: '', repositoryUrl: '',
      thumbnailUrl: '', thumbnailAltText: '', status,
      createdAt: new Date('2025-01-01T00:00:00Z'),
      updatedAt: new Date('2025-01-01T00:00:00Z'),
    });
    await setDoc(doc(db, 'portfolio_projects/seeker-draft'), project('seeker', 'draft'));
    await setDoc(doc(db, 'portfolio_projects/seeker-published'), project('seeker', 'published'));
    await setDoc(doc(db, 'portfolio_projects/other-draft'), project('other', 'draft'));
    await setDoc(doc(db, 'portfolio_projects/other-published'), project('other', 'published'));
    await setDoc(doc(db, 'portfolio_projects/private-published'), project('private', 'published'));
    await setDoc(doc(db, 'portfolio_projects/seeker-archived'), project('seeker', 'archived'));

    const thread = (authorUid, authorName, publicationStatus, moderationStatus = 'visible', publishedAt = new Date('2025-02-01T00:00:00Z')) => ({
      authorUid, authorName, authorHeadline: 'Professional member',
      contentType: 'professionalInsight', title: 'A professional insight',
      content: 'A published HABI Thread.', skills: ['Flutter'], topics: ['Learning'],
      externalUrl: '', portfolioProjectId: null, challenge: '', approach: '',
      outcome: '', learning: '', collaboration: '', publicationStatus,
      moderationStatus, createdAt: new Date('2025-01-01T00:00:00Z'),
      updatedAt: new Date('2025-02-01T00:00:00Z'),
      publishedAt: publicationStatus === 'draft' ? null : publishedAt,
    });
    await setDoc(doc(db, 'posts/seeker-draft'), thread('seeker', 'Seeker', 'draft'));
    await setDoc(doc(db, 'posts/seeker-visible'), thread('seeker', 'Seeker', 'published'));
    await setDoc(doc(db, 'posts/other-visible'), thread('other', 'Other Member', 'published', 'visible', new Date('2025-03-01T00:00:00Z')));
    await setDoc(doc(db, 'posts/other-hidden'), thread('other', 'Other Member', 'published', 'hidden'));
    await setDoc(doc(db, 'posts/private-visible'), thread('private', 'Private Member', 'published'));
    await setDoc(doc(db, 'posts/seeker-deleted'), thread('seeker', 'Seeker', 'deleted'));
    await setDoc(doc(db, 'posts/other-visible/comments/comment-1'), {
      authorUid: 'other', authorName: 'Other Member', body: 'A comment',
      createdAt: new Date('2025-03-02T00:00:00Z'), updatedAt: new Date('2025-03-02T00:00:00Z'),
    });
    await setDoc(doc(db, 'posts/other-visible/reactions/seeker'), {
      userUid: 'seeker', reactionType: 'support', createdAt: new Date('2025-03-02T00:00:00Z'),
    });
    await setDoc(doc(db, 'posts/seeker-visible/comments/comment-1'), {
      authorUid: 'other', authorName: 'Other Member', body: 'A comment',
      createdAt: new Date('2025-02-02T00:00:00Z'), updatedAt: new Date('2025-02-02T00:00:00Z'),
    });
    await setDoc(doc(db, 'posts/seeker-visible/reactions/seeker'), {
      userUid: 'seeker', reactionType: 'support', createdAt: new Date('2025-02-02T00:00:00Z'),
    });
    await setDoc(doc(db, 'posts/seeker-deleted/comments/orphan'), {
      authorUid: 'seeker', authorName: 'Seeker', body: 'Orphaned comment',
      createdAt: new Date('2025-02-03T00:00:00Z'), updatedAt: new Date('2025-02-03T00:00:00Z'),
    });
    await setDoc(doc(db, 'posts/seeker-deleted/reactions/other'), {
      userUid: 'other', reactionType: 'support', createdAt: new Date('2025-02-03T00:00:00Z'),
    });
  });
});

after(async () => env?.cleanup());

describe('HABI Firestore governance rules', () => {
  it('allows seekers to read only approved published jobs', async () => {
    const db = env.authenticatedContext('seeker').firestore();
    await assertSucceeds(getDoc(doc(db, 'jobs/approved')));
    await assertFails(getDoc(doc(db, 'jobs/pending')));
    await assertFails(getDoc(doc(db, 'jobs/draft')));
  });

  it('allows employers to inspect their private listings but not another owner’s', async () => {
    const db = env.authenticatedContext('employer').firestore();
    await assertSucceeds(getDoc(doc(db, 'jobs/pending')));
    await assertSucceeds(getDoc(doc(db, 'jobs/draft')));
    await env.withSecurityRulesDisabled((context) => setDoc(doc(context.firestore(), 'jobs/other'), {
      ownerId: 'someone-else', status: 'draft', title: 'Private',
    }));
    await assertFails(getDoc(doc(db, 'jobs/other')));
  });

  it('prevents employers from changing moderation state or approved listing content', async () => {
    const db = env.authenticatedContext('employer').firestore();
    await assertFails(updateDoc(doc(db, 'jobs/pending'), { moderationStatus: 'approved' }));
    await assertFails(updateDoc(doc(db, 'jobs/approved'), { title: 'Changed without review' }));
  });

  it('requires approved publication for saved jobs and applications', async () => {
    const db = env.authenticatedContext('seeker').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/seeker/saved_jobs/approved'), { jobId: 'approved' }));
    await assertFails(setDoc(doc(db, 'users/seeker/saved_jobs/pending'), { jobId: 'pending' }));
    const profile = {
      displayName: 'Seeker', professionalSummary: '', education: '', certifications: [],
      skills: [], workExperience: '', employmentType: '', workArrangement: '',
      preferredLocation: '', availabilityDays: [], availabilityTime: '',
      beneficiaryCategories: [], accessibility: [], shareBeneficiary: true,
      shareAccessibility: true, visibility: true, profileComplete: true,
    };
    const job = {
      title: 'Approved role', postedBy: 'Employer', location: 'Remote', setup: 'Remote',
      type: 'Full-time', pay: 'PHP 30,000', description: 'Role', experience: 'Entry',
      workSchedule: 'Flexible', accessibility: 'Flexible', requirements: 'Skills',
      postedAt: new Date(),
    };
    await assertSucceeds(setDoc(doc(db, 'applications/approved_seeker'), {
      jobId: 'approved', applicantId: 'seeker', applicantName: 'Seeker', employerId: 'employer',
      jobTitle: 'Approved role', status: 'Submitted', appliedAt: new Date(), updatedAt: new Date(),
      profileSnapshot: profile, jobSnapshot: job,
    }));
    await assertFails(setDoc(doc(db, 'applications/pending_seeker'), {
      jobId: 'pending', applicantId: 'seeker', applicantName: 'Seeker', employerId: 'employer',
      jobTitle: 'Pending role', status: 'Submitted', appliedAt: new Date(), updatedAt: new Date(),
      profileSnapshot: profile, jobSnapshot: {...job, title: 'Pending role'},
    }));
  });

  it('submits an application with an employer notification and secures status updates', async () => {
    const seeker = env.authenticatedContext('seeker').firestore();
    const employer = env.authenticatedContext('employer').firestore();
    const other = env.authenticatedContext('other').firestore();
    const applicationId = 'approved-flow_seeker';
    const profileSnapshot = {
      displayName: 'Seeker', professionalSummary: '', education: '',
      certifications: [], skills: [], workExperience: '', employmentType: '',
      workArrangement: '', preferredLocation: '', availabilityDays: [],
      availabilityTime: '', beneficiaryCategories: [], accessibility: [],
      shareBeneficiary: true, shareAccessibility: true, visibility: true,
      profileComplete: true,
    };
    const jobSnapshot = {
      title: 'Workflow role', postedBy: 'Employer', location: 'Remote',
      setup: 'Remote', type: 'Full-time', pay: 'PHP 30,000',
      description: 'Role', experience: 'Entry', workSchedule: 'Flexible',
      accessibility: 'Flexible', requirements: 'Flutter',
      postedAt: new Date('2025-01-01T00:00:00Z'),
    };
    const applicationBatch = writeBatch(seeker);
    applicationBatch.set(doc(seeker, `applications/${applicationId}`), {
      jobId: 'approved-flow', applicantId: 'seeker', applicantName: 'Seeker',
      employerId: 'employer', jobTitle: 'Workflow role', status: 'Submitted',
      appliedAt: serverTimestamp(), updatedAt: serverTimestamp(),
      profileSnapshot, jobSnapshot,
    });
    applicationBatch.set(doc(seeker, `users/employer/notifications/${applicationId}`), {
      kind: 'application', title: 'New application received',
      body: 'Seeker applied for Workflow role.', jobId: 'approved-flow',
      applicationId, applicantId: 'seeker', createdAt: serverTimestamp(),
      read: false,
    });
    await assertSucceeds(applicationBatch.commit());
    await assertFails(setDoc(doc(seeker, `applications/${applicationId}`), {
      jobId: 'approved-flow', applicantId: 'seeker', applicantName: 'Seeker',
      employerId: 'employer', jobTitle: 'Workflow role', status: 'Submitted',
      appliedAt: serverTimestamp(), updatedAt: serverTimestamp(),
      profileSnapshot, jobSnapshot,
    }));
    await assertSucceeds(getDoc(doc(employer, `applications/${applicationId}`)));
    await assertFails(getDoc(doc(other, `applications/${applicationId}`)));
    await assertFails(updateDoc(doc(seeker, `applications/${applicationId}`), {
      status: 'Hired', updatedAt: serverTimestamp(),
    }));

    const statusBatch = writeBatch(employer);
    statusBatch.update(doc(employer, `applications/${applicationId}`), {
      status: 'Under Review', statusNotificationId: 'status-flow-1', updatedAt: serverTimestamp(),
    });
    statusBatch.set(doc(employer, 'users/seeker/notifications/status-flow-1'), {
      kind: 'status', title: 'Application update',
      body: 'Your application is under review.', jobId: 'approved-flow',
      applicationId, applicationStatus: 'Under Review',
      createdAt: serverTimestamp(), read: false,
    });
    await assertSucceeds(statusBatch.commit());
    await assertSucceeds(getDoc(doc(seeker, 'users/seeker/notifications/status-flow-1')));

    const unpairedBatch = writeBatch(employer);
    unpairedBatch.update(doc(employer, `applications/${applicationId}`), {
      status: 'Shortlisted', statusNotificationId: 'missing-status-notification', updatedAt: serverTimestamp(),
    });
    await assertFails(unpairedBatch.commit());

    const shortlist = writeBatch(employer);
    shortlist.update(doc(employer, `applications/${applicationId}`), {
      status: 'Shortlisted', statusNotificationId: 'status-flow-shortlisted',
      updatedAt: serverTimestamp(),
    });
    shortlist.set(doc(employer, 'users/seeker/notifications/status-flow-shortlisted'), {
      kind: 'status', title: 'Shortlisted', body: 'You were shortlisted.',
      jobId: 'approved-flow', applicationId, applicationStatus: 'Shortlisted',
      createdAt: serverTimestamp(), read: false,
    });
    await assertSucceeds(shortlist.commit());

    const interviewBatch = writeBatch(employer);
    const interviewId = 'approved-flow_seeker_interview-1';
    const interviewNotificationId = 'status-flow-interview';
    interviewBatch.set(doc(employer, `interviews/${interviewId}`), {
      interviewId, applicationId, jobId: 'approved-flow', employerId: 'employer',
      applicantId: 'seeker', startsAt: new Date('2026-12-01T10:00:00Z'),
      endsAt: new Date('2026-12-01T11:00:00Z'), format: 'Online',
      locationOrLink: 'https://meet.example.com/room', instructions: '',
      createdBy: 'employer', status: 'scheduled', applicantResponse: 'pending',
      applicantResponseNote: '', createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(), jobTitle: 'Workflow role',
    });
    interviewBatch.update(doc(employer, `applications/${applicationId}`), {
      status: 'Interview Scheduled', interviewId,
      statusNotificationId: interviewNotificationId, updatedAt: serverTimestamp(),
    });
    interviewBatch.set(doc(employer, `users/seeker/notifications/${interviewNotificationId}`), {
      kind: 'status', title: 'Interview scheduled',
      body: 'An interview has been scheduled.', jobId: 'approved-flow',
      applicationId, applicationStatus: 'Interview Scheduled',
      createdAt: serverTimestamp(), read: false,
    });
    await assertSucceeds(interviewBatch.commit());
  });

  it('enforces Firestore suspension and supports audited Admin restoration', async () => {
    const suspended = env.authenticatedContext('suspended').firestore();
    const admin = env.authenticatedContext('admin', { admin: true }).firestore();
    await assertSucceeds(getDoc(doc(suspended, 'users/suspended')));
    await assertFails(getDocs(query(
      collection(suspended, 'jobs'),
      where('status', '==', 'published'),
      where('moderationStatus', '==', 'approved'),
    )));
    await assertFails(getDocs(collection(suspended, 'posts')));

    const batch = writeBatch(admin);
    batch.update(doc(admin, 'users/other'), {
      accountStatus: 'suspended', accountStatusUpdatedAt: serverTimestamp(),
      accountStatusUpdatedBy: 'admin', accountStatusAuditId: 'user-audit-suspend',
    });
    batch.update(doc(admin, 'admin_user_directory/other'), {
      accountStatus: 'suspended', statusChangedAt: serverTimestamp(),
      statusChangedBy: 'admin', statusAuditId: 'user-audit-suspend', updatedAt: serverTimestamp(),
    });
    batch.set(doc(admin, 'admin_audit/user-audit-suspend'), {
      action: 'user_account_suspended', targetType: 'user', targetId: 'other',
      actorId: 'admin', reviewerId: 'admin', previousStatus: 'active',
      status: 'suspended', reason: 'Test restriction', createdAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
    await assertFails(getDocs(query(
      collection(env.authenticatedContext('other').firestore(), 'jobs'),
      where('status', '==', 'published'),
      where('moderationStatus', '==', 'approved'),
    )));

    const restore = writeBatch(admin);
    restore.update(doc(admin, 'users/other'), {
      accountStatus: 'active', accountStatusUpdatedAt: serverTimestamp(),
      accountStatusUpdatedBy: 'admin', accountStatusAuditId: 'user-audit-restore',
    });
    restore.update(doc(admin, 'admin_user_directory/other'), {
      accountStatus: 'active', statusChangedAt: serverTimestamp(),
      statusChangedBy: 'admin', statusAuditId: 'user-audit-restore', updatedAt: serverTimestamp(),
    });
    restore.set(doc(admin, 'admin_audit/user-audit-restore'), {
      action: 'user_account_restored', targetType: 'user', targetId: 'other',
      actorId: 'admin', reviewerId: 'admin', previousStatus: 'suspended',
      status: 'active', reason: 'Test restoration', createdAt: serverTimestamp(),
    });
    await assertSucceeds(restore.commit());
  });

  it('keeps the Admin directory role-bound and privacy-limited', async () => {
    const seeker = env.authenticatedContext('seeker').firestore();
    const newMember = env.authenticatedContext('new-member').firestore();
    const admin = env.authenticatedContext('admin', { admin: true }).firestore();
    const registration = writeBatch(newMember);
    registration.set(doc(newMember, 'users/new-member'), {
      uid: 'new-member', email: 'member@example.com', displayName: 'New Member',
      role: 'jobSeeker', accountStatus: 'active', createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    registration.set(doc(newMember, 'admin_user_directory/new-member'), {
      uid: 'new-member', email: 'member@example.com', displayName: 'New Member',
      role: 'jobSeeker', accountStatus: 'active', createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await assertSucceeds(registration.commit());
    await assertFails(getDocs(collection(seeker, 'admin_user_directory')));
    const directory = await assertSucceeds(getDocs(collection(admin, 'admin_user_directory')));
    assert.ok(directory.docs.some((entry) => entry.id === 'new-member'));
    await assertFails(updateDoc(doc(newMember, 'admin_user_directory/new-member'), {
      role: 'employer', updatedAt: serverTimestamp(),
    }));
  });

  it('denies new Firestore file and chunk writes', async () => {
    const seeker = env.authenticatedContext('seeker').firestore();
    await assertFails(setDoc(doc(seeker, 'file_uploads/new-file'), {
      fileId: 'new-file', ownerUid: 'seeker', fileName: 'resume.pdf',
      contentType: 'application/pdf', kind: 'profileResume', sizeBytes: 5,
      chunkCount: 1, createdAt: serverTimestamp(),
    }));
  });

  it('allows an Admin to update moderation only with a paired append-only audit record', async () => {
    const db = env.authenticatedContext('admin', { admin: true }).firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'jobs/pending'), {
      moderationStatus: 'approved', moderationReason: '', moderationBy: 'admin',
      moderationUpdatedAt: serverTimestamp(), moderationAuditId: 'audit-1',
    });
    batch.set(doc(db, 'admin_audit/audit-1'), {
      action: 'job_moderation_approved', targetType: 'job', targetId: 'pending',
      actorId: 'admin', reviewerId: 'admin', previousStatus: 'pending_review',
      status: 'approved', reason: '', createdAt: serverTimestamp(),
    });
    batch.set(doc(db, 'users/employer/notifications/audit-1'), {
      kind: 'status', title: 'Job listing approved', body: 'Your listing was approved.',
      jobId: 'pending', createdAt: serverTimestamp(), read: false,
    });
    await assertSucceeds(batch.commit());
    await assertFails(updateDoc(doc(db, 'admin_audit/audit-1'), { reason: 'rewritten' }));
    await assertFails(getDoc(doc(db, 'users/seeker/notifications/audit-1')));
  });

  it('denies unauthenticated reads and self-assigned roles', async () => {
    const guest = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(guest, 'jobs/approved')));
    await assertFails(getDoc(doc(guest, 'portfolio_projects/seeker-published')));
    const seeker = env.authenticatedContext('seeker').firestore();
    await assertFails(updateDoc(doc(seeker, 'users/seeker'), { uid: 'seeker', role: 'admin' }));
    await assertFails(getDoc(doc(seeker, 'users/employer')));
    await assertFails(getDoc(doc(seeker, 'admin_audit/audit-1')));
  });

  it('keeps drafts owner-only and exposes published projects only for visible profiles', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const other = env.authenticatedContext('other').firestore();
    const admin = env.authenticatedContext('admin', { admin: true }).firestore();

    await assertSucceeds(getDoc(doc(owner, 'portfolio_projects/seeker-draft')));
    await assertFails(getDoc(doc(other, 'portfolio_projects/seeker-draft')));
    await assertSucceeds(getDoc(doc(other, 'portfolio_projects/seeker-published')));
    await assertFails(getDoc(doc(other, 'portfolio_projects/private-published')));
    await assertSucceeds(getDoc(doc(admin, 'portfolio_projects/seeker-draft')));
    const missing = await assertSucceeds(getDoc(doc(other, 'portfolio_projects/deleted-project')));
    assert.equal(missing.exists(), false);

    const publicProjects = await assertSucceeds(getDocs(query(
      collection(other, 'portfolio_projects'),
      where('ownerUid', '==', 'seeker'),
      where('status', '==', 'published'),
      orderBy('updatedAt', 'desc'),
    )));
    assert.equal(publicProjects.size, 1);
    const ownerProjects = await assertSucceeds(getDocs(query(
      collection(owner, 'portfolio_projects'),
      where('ownerUid', '==', 'seeker'),
      orderBy('updatedAt', 'desc'),
    )));
    assert.equal(ownerProjects.size, 3);
  });

  it('allows valid own project creation and rejects spoofed ownership or malformed data', async () => {
    const seeker = env.authenticatedContext('seeker').firestore();
    const data = {
      ownerUid: 'seeker', title: 'My project', summary: 'Summary',
      description: 'Description', category: '', role: '', skills: [],
      technologies: [], responsibilities: '', outcomes: '', reflection: '',
      startedAt: new Date('2025-01-01T00:00:00Z'), endedAt: null,
      ongoing: true, demoUrl: 'https://example.org/demo', repositoryUrl: '',
      thumbnailUrl: '', thumbnailAltText: '', status: 'draft',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    };
    await assertSucceeds(setDoc(doc(seeker, 'portfolio_projects/created-own'), data));
    await assertFails(setDoc(doc(seeker, 'portfolio_projects/created-other'), {
      ...data, ownerUid: 'other',
    }));
    await assertFails(setDoc(doc(seeker, 'portfolio_projects/invalid-url'), {
      ...data, demoUrl: 'http://example.org',
    }));
    await assertFails(setDoc(doc(seeker, 'portfolio_projects/empty-host-url'), {
      ...data, demoUrl: 'https://',
    }));
    await assertFails(setDoc(doc(seeker, 'portfolio_projects/missing-required'), {
      ownerUid: 'seeker', title: 'Incomplete',
    }));
  });

  it('lets owners update and publish their projects but blocks ownership and protected-field changes', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const other = env.authenticatedContext('other').firestore();
    await assertSucceeds(updateDoc(doc(owner, 'portfolio_projects/seeker-draft'), {
      title: 'Updated project', updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(owner, 'portfolio_projects/seeker-draft'), {
      status: 'published', updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(owner, 'portfolio_projects/seeker-draft'), {
      status: 'draft', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'portfolio_projects/seeker-draft'), {
      ownerUid: 'other', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'portfolio_projects/seeker-draft'), {
      moderationStatus: 'approved', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(other, 'portfolio_projects/seeker-published'), {
      title: 'Changed by another user', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'portfolio_projects/seeker-archived'), {
      status: 'published', updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(owner, 'portfolio_projects/archived-create'), {
      ownerUid: 'seeker', title: 'Archive', summary: 'Summary',
      description: 'Description', category: '', role: '', skills: [],
      technologies: [], responsibilities: '', outcomes: '', reflection: '',
      startedAt: new Date('2025-01-01T00:00:00Z'), endedAt: null,
      ongoing: true, demoUrl: '', repositoryUrl: '', thumbnailUrl: '',
      thumbnailAltText: '', status: 'archived', createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertFails(deleteDoc(doc(other, 'portfolio_projects/seeker-published')));
    await assertSucceeds(deleteDoc(doc(owner, 'portfolio_projects/seeker-archived')));
  });

  it('protects draft privacy and exposes only published visible Threads', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const member = env.authenticatedContext('other').firestore();
    const guest = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(owner, 'posts/seeker-draft')));
    await assertFails(getDoc(doc(member, 'posts/seeker-draft')));
    await assertSucceeds(getDoc(doc(member, 'posts/seeker-visible')));
    await assertSucceeds(getDoc(doc(member, 'posts/private-visible')));
    await assertFails(getDoc(doc(owner, 'posts/other-hidden')));
    await assertFails(getDoc(doc(member, 'posts/seeker-deleted')));
    await assertFails(getDoc(doc(guest, 'posts/seeker-visible')));

    const firstPage = await assertSucceeds(getDocs(query(
      collection(member, 'posts'),
      where('publicationStatus', '==', 'published'),
      where('moderationStatus', '==', 'visible'),
      orderBy('publishedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(2),
    )));
    assert.deepEqual(firstPage.docs.map((post) => post.id), ['other-visible', 'seeker-visible']);
    const secondPage = await assertSucceeds(getDocs(query(
      collection(member, 'posts'),
      where('publicationStatus', '==', 'published'),
      where('moderationStatus', '==', 'visible'),
      orderBy('publishedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      startAfter(firstPage.docs.at(-1)),
      limit(2),
    )));
    assert.deepEqual(secondPage.docs.map((post) => post.id), ['private-visible']);
    const filtered = await assertSucceeds(getDocs(query(
      collection(member, 'posts'),
      where('publicationStatus', '==', 'published'),
      where('moderationStatus', '==', 'visible'),
      where('contentType', '==', 'professionalInsight'),
      where('skills', 'array-contains', 'Flutter'),
      orderBy('publishedAt', 'desc'),
      orderBy(documentId(), 'desc'),
    )));
    assert.deepEqual(filtered.docs.map((post) => post.id), [
      'other-visible', 'seeker-visible', 'private-visible',
    ]);
    await assertFails(getDocs(collection(member, 'posts')));
  });

  it('validates owned Thread creation, drafts, publication, and project references', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const other = env.authenticatedContext('other').firestore();
    const guest = env.unauthenticatedContext().firestore();
    const draft = {
      authorUid: 'seeker', authorName: 'Seeker', authorHeadline: '',
      contentType: 'projectShowcase', title: '', content: '', skills: [], topics: [],
      externalUrl: '', portfolioProjectId: null, challenge: '', approach: '',
      outcome: '', learning: '', collaboration: '', publicationStatus: 'draft',
      moderationStatus: 'visible', createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(), publishedAt: null,
    };
    await assertFails(setDoc(doc(guest, 'posts/unauthenticated'), draft));
    await assertSucceeds(setDoc(doc(owner, 'posts/new-draft'), draft));
    await assertFails(setDoc(doc(owner, 'posts/spoofed'), {...draft, authorUid: 'other'}));
    await assertFails(setDoc(doc(owner, 'posts/spoofed-name'), {...draft, authorName: 'Other Member'}));
    await assertFails(setDoc(doc(owner, 'posts/invalid-url'), {...draft, externalUrl: 'http://example.org'}));
    await assertFails(setDoc(doc(owner, 'posts/invalid-type'), {...draft, contentType: 'socialMedia'}));
    await assertFails(setDoc(doc(owner, 'posts/malformed'), {authorUid: 'seeker'}));
    await assertFails(setDoc(doc(owner, 'posts/empty-public'), {
      ...draft, contentType: 'professionalInsight', publicationStatus: 'published',
      publishedAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(owner, 'posts/project-reference'), {
      ...draft, title: 'A project', content: 'What I learned',
      portfolioProjectId: 'seeker-published',
    }));
    await assertFails(setDoc(doc(owner, 'posts/other-project-reference'), {
      ...draft, title: 'A project', content: 'What I learned',
      portfolioProjectId: 'other-published',
    }));
    await assertFails(setDoc(doc(owner, 'posts/archived-project-reference'), {
      ...draft, title: 'A project', content: 'What I learned',
      portfolioProjectId: 'seeker-archived',
    }));
    await assertFails(getDoc(doc(other, 'posts/new-draft')));
  });

  it('lets authors edit their Threads but protects ownership, creation, moderation, and publication time', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const other = env.authenticatedContext('other').firestore();
    await assertSucceeds(updateDoc(doc(owner, 'posts/seeker-draft'), {
      title: 'A saved draft', updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(owner, 'posts/seeker-draft'), {
      contentType: 'professionalInsight', content: 'Published content',
      publicationStatus: 'published', publishedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(owner, 'posts/seeker-visible'), {
      content: 'An edited professional insight', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(other, 'posts/seeker-visible'), {
      content: 'Changed by another author', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'posts/seeker-visible'), {
      authorUid: 'other', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'posts/seeker-visible'), {
      moderationStatus: 'hidden', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'posts/seeker-visible'), {
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'posts/seeker-visible'), {
      publishedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'posts/seeker-deleted'), {
      publicationStatus: 'published', updatedAt: serverTimestamp(),
    }));
  });

  it('allows id-bound reactions and blocks impersonation, updates, and hidden-post reactions', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const other = env.authenticatedContext('other').firestore();
    const ownerReaction = doc(owner, 'posts/other-visible/reactions/seeker');
    const otherReaction = doc(other, 'posts/other-visible/reactions/other');
    await assertSucceeds(setDoc(otherReaction, {
      userUid: 'other', reactionType: 'support', createdAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(other, 'posts/other-visible/reactions/seeker'), {
      userUid: 'seeker', reactionType: 'support', createdAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(otherReaction, {reactionType: 'support'}));
    await assertSucceeds(deleteDoc(otherReaction));
    await assertSucceeds(deleteDoc(ownerReaction));
    await assertFails(setDoc(doc(owner, 'posts/other-hidden/reactions/seeker'), {
      userUid: 'seeker', reactionType: 'support', createdAt: serverTimestamp(),
    }));
  });

  it('supports comments only on visible posts and locks comment ownership', async () => {
    const owner = env.authenticatedContext('seeker').firestore();
    const other = env.authenticatedContext('other').firestore();
    const ownComment = doc(owner, 'posts/other-visible/comments/new-comment');
    await assertSucceeds(setDoc(ownComment, {
      authorUid: 'seeker', authorName: 'Seeker', body: 'Helpful note',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(ownComment, {
      body: 'Edited note', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, 'posts/other-visible/comments/comment-1'), {
      body: 'Changed by another person', updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(owner, 'posts/other-visible/comments/spoofed'), {
      authorUid: 'other', authorName: 'Other Member', body: 'Spoofed',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(owner, 'posts/other-hidden/comments/blocked'), {
      authorUid: 'seeker', authorName: 'Seeker', body: 'Blocked',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(owner, 'posts/seeker-deleted/comments/blocked'), {
      authorUid: 'seeker', authorName: 'Seeker', body: 'Blocked',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(deleteDoc(ownComment));
  });

  it('grants custom-claim Admin access and makes nested records inaccessible after soft deletion', async () => {
    const admin = env.authenticatedContext('admin', {admin: true}).firestore();
    const member = env.authenticatedContext('other').firestore();
    const owner = env.authenticatedContext('seeker').firestore();
    await assertSucceeds(getDoc(doc(admin, 'posts/other-hidden')));
    await assertSucceeds(getDoc(doc(admin, 'posts/seeker-draft')));
    await assertSucceeds(getDoc(doc(admin, 'posts/seeker-deleted/comments/orphan')));
    await assertSucceeds(getDoc(doc(admin, 'posts/seeker-deleted/reactions/other')));
    await assertFails(updateDoc(doc(owner, 'posts/seeker-visible'), {
      moderationStatus: 'hidden', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(admin, 'posts/seeker-visible'), {
      moderationStatus: 'hidden', updatedAt: serverTimestamp(),
    }));

    await assertSucceeds(updateDoc(doc(owner, 'posts/seeker-visible'), {
      publicationStatus: 'deleted', updatedAt: serverTimestamp(),
    }));
    await assertFails(getDoc(doc(member, 'posts/seeker-visible/comments/comment-1')));
    await assertFails(getDoc(doc(member, 'posts/seeker-visible/reactions/seeker')));
  });
});
